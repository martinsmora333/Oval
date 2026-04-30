create or replace function public.create_booking_workflow(
  target_center_id uuid,
  target_court_id uuid,
  target_starts_at timestamptz,
  target_ends_at timestamptz,
  booking_total_amount numeric(10, 2) default 0,
  booking_amount_per_player numeric(10, 2) default 0,
  booking_currency text default 'AUD',
  initial_invitee_ids uuid[] default null,
  invitation_message text default null,
  invitation_response_window_minutes integer default 120
)
returns table (
  booking_id uuid,
  booking_status public.booking_status,
  activated_invitation_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  court_record public.courts%rowtype;
  created_booking public.bookings%rowtype;
  invitee_id uuid;
  next_priority integer := 1;
  activated_id uuid := null;
  normalized_message text := nullif(btrim(invitation_message), '');
  center_timezone text;
  requested_duration_minutes integer;
  requested_local_date date;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if target_center_id is null or target_court_id is null then
    raise exception 'Center and court are required';
  end if;

  if target_starts_at is null or target_ends_at is null or target_ends_at <= target_starts_at then
    raise exception 'Booking end time must be after start time';
  end if;

  if target_starts_at <= timezone('utc', now()) then
    raise exception 'Bookings must start in the future';
  end if;

  if coalesce(booking_currency, '') = '' or char_length(booking_currency) <> 3 then
    raise exception 'Booking currency must be a 3-character ISO code';
  end if;

  if invitation_response_window_minutes not between 5 and 10080 then
    raise exception 'Invitation response window must be between 5 and 10080 minutes';
  end if;

  select *
  into court_record
  from public.courts
  where id = target_court_id;

  if not found then
    raise exception 'Court % not found', target_court_id;
  end if;

  if court_record.center_id <> target_center_id then
    raise exception 'Court % does not belong to center %', target_court_id, target_center_id;
  end if;

  if court_record.status <> 'active'::public.court_status then
    raise exception 'Court % is not available for booking', target_court_id;
  end if;

  select tc.timezone_name
  into center_timezone
  from public.tennis_centers tc
  where tc.id = target_center_id;

  if center_timezone is null then
    raise exception 'Tennis center % not found', target_center_id;
  end if;

  requested_duration_minutes :=
    greatest(1, (extract(epoch from (target_ends_at - target_starts_at)) / 60)::integer);
  requested_local_date := (target_starts_at at time zone center_timezone)::date;

  if not exists (
    select 1
    from public.get_court_day_availability(
      target_court_id,
      requested_local_date,
      requested_duration_minutes
    ) slot
    where slot.starts_at = target_starts_at
      and slot.ends_at = target_ends_at
      and slot.status = 'available'
  ) then
    raise exception 'Selected slot is no longer available';
  end if;

  insert into public.bookings (
    center_id,
    court_id,
    created_by,
    status,
    payment_status,
    total_amount,
    amount_per_player,
    currency,
    starts_at,
    ends_at
  )
  values (
    target_center_id,
    target_court_id,
    actor_id,
    'pending'::public.booking_status,
    'pending'::public.payment_status,
    coalesce(booking_total_amount, 0),
    coalesce(booking_amount_per_player, 0),
    upper(booking_currency),
    target_starts_at,
    target_ends_at
  )
  returning * into created_booking;

  foreach invitee_id in array coalesce(initial_invitee_ids, array[]::uuid[])
  loop
    if invitee_id is null then
      continue;
    end if;

    if invitee_id = actor_id then
      raise exception 'You cannot invite yourself';
    end if;

    if exists (
      select 1
      from public.booking_invitations
      where booking_id = created_booking.id
        and invitee_user_id = invitee_id
    ) then
      continue;
    end if;

    insert into public.booking_invitations (
      booking_id,
      creator_user_id,
      invitee_user_id,
      priority,
      status,
      message,
      response_window_minutes
    )
    values (
      created_booking.id,
      actor_id,
      invitee_id,
      next_priority,
      'queued'::public.invitation_status,
      normalized_message,
      invitation_response_window_minutes
    );

    next_priority := next_priority + 1;
  end loop;

  if next_priority > 1 then
    update public.bookings
    set hold_expires_at = null,
        updated_at = timezone('utc', now())
    where id = created_booking.id;

    activated_id := public.activate_next_booking_invitation(created_booking.id);

    select *
    into created_booking
    from public.bookings
    where id = created_booking.id;
  end if;

  return query
  select created_booking.id, created_booking.status, activated_id;
end;
$$;

revoke all on function public.create_booking_workflow(
  uuid,
  uuid,
  timestamptz,
  timestamptz,
  numeric,
  numeric,
  text,
  uuid[],
  text,
  integer
) from public, anon;

grant execute on function public.create_booking_workflow(
  uuid,
  uuid,
  timestamptz,
  timestamptz,
  numeric,
  numeric,
  text,
  uuid[],
  text,
  integer
) to authenticated;
