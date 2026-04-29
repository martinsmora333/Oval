create extension if not exists pg_cron;

create or replace function public.guard_booking_workflow_mutations()
returns trigger
language plpgsql
as $$
begin
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if new.legacy_firebase_id is distinct from old.legacy_firebase_id
     or new.center_id is distinct from old.center_id
     or new.court_id is distinct from old.court_id
     or new.created_by is distinct from old.created_by
     or new.opponent_user_id is distinct from old.opponent_user_id
     or new.status is distinct from old.status
     or new.total_amount is distinct from old.total_amount
     or new.amount_per_player is distinct from old.amount_per_player
     or new.currency is distinct from old.currency
     or new.starts_at is distinct from old.starts_at
     or new.ends_at is distinct from old.ends_at
     or new.notes is distinct from old.notes
     or new.confirmed_at is distinct from old.confirmed_at
     or new.cancelled_at is distinct from old.cancelled_at
     or new.completed_at is distinct from old.completed_at
     or new.hold_expires_at is distinct from old.hold_expires_at
     or new.cancel_reason is distinct from old.cancel_reason then
    raise exception 'Direct booking workflow updates are not allowed from the client';
  end if;

  return new;
end;
$$;

drop trigger if exists bookings_guard_workflow_mutations on public.bookings;
create trigger bookings_guard_workflow_mutations
before update on public.bookings
for each row
execute function public.guard_booking_workflow_mutations();

create or replace function public.respond_to_booking_invitation(
  target_invitation_id uuid,
  new_status public.invitation_status
)
returns table (
  booking_id uuid,
  booking_status public.booking_status,
  next_invitation_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_record public.booking_invitations%rowtype;
  booking_record public.bookings%rowtype;
  activated_invitation_id uuid;
begin
  if new_status not in (
    'accepted'::public.invitation_status,
    'declined'::public.invitation_status,
    'cancelled'::public.invitation_status
  ) then
    raise exception 'Unsupported invitation response %', new_status;
  end if;

  select *
  into invitation_record
  from public.booking_invitations
  where id = target_invitation_id
  for update;

  if not found then
    raise exception 'Invitation % not found', target_invitation_id;
  end if;

  if invitation_record.status <> 'pending'::public.invitation_status then
    raise exception 'Invitation % is not pending', target_invitation_id;
  end if;

  if invitation_record.expires_at is not null
     and invitation_record.expires_at <= timezone('utc', now()) then
    raise exception 'Invitation % has expired', target_invitation_id;
  end if;

  select *
  into booking_record
  from public.bookings
  where id = invitation_record.booking_id
  for update;

  if not found then
    raise exception 'Booking % not found', invitation_record.booking_id;
  end if;

  if booking_record.status <> 'pending'::public.booking_status then
    raise exception 'Booking % is not pending', invitation_record.booking_id;
  end if;

  if new_status in ('accepted'::public.invitation_status, 'declined'::public.invitation_status)
     and auth.uid() <> invitation_record.invitee_user_id then
    raise exception 'Only the invited player can respond to this invitation';
  end if;

  if new_status = 'cancelled'::public.invitation_status
     and auth.uid() not in (invitation_record.creator_user_id, invitation_record.invitee_user_id)
     and not public.is_tennis_center_manager(booking_record.center_id) then
    raise exception 'You are not allowed to cancel this invitation';
  end if;

  update public.booking_invitations
  set status = new_status,
      responded_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  where id = invitation_record.id;

  if new_status = 'accepted'::public.invitation_status then
    update public.bookings
    set opponent_user_id = invitation_record.invitee_user_id,
        status = 'confirmed'::public.booking_status,
        confirmed_at = timezone('utc', now()),
        updated_at = timezone('utc', now())
    where id = invitation_record.booking_id;

    update public.booking_invitations
    set status = 'cancelled'::public.invitation_status,
        responded_at = coalesce(responded_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where booking_id = invitation_record.booking_id
      and id <> invitation_record.id
      and status in ('queued'::public.invitation_status, 'pending'::public.invitation_status);

    return query
    select invitation_record.booking_id, 'confirmed'::public.booking_status, null::uuid;

    return;
  end if;

  activated_invitation_id := public.activate_next_booking_invitation(invitation_record.booking_id);

  return query
  select b.id, b.status, activated_invitation_id
  from public.bookings b
  where b.id = invitation_record.booking_id;
end;
$$;

revoke all on function public.respond_to_booking_invitation(uuid, public.invitation_status) from public, anon;
grant execute on function public.respond_to_booking_invitation(uuid, public.invitation_status) to authenticated;

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

create or replace function public.queue_booking_invitation(
  target_booking_id uuid,
  target_invitee_user_id uuid,
  invitation_message text default null,
  invitation_response_window_minutes integer default 120
)
returns table (
  invitation_id uuid,
  invitation_status public.invitation_status,
  invitation_priority integer,
  activated_invitation_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  booking_record public.bookings%rowtype;
  created_invitation public.booking_invitations%rowtype;
  next_priority integer;
  activated_id uuid := null;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  if target_booking_id is null or target_invitee_user_id is null then
    raise exception 'Booking and invitee are required';
  end if;

  if target_invitee_user_id = actor_id then
    raise exception 'You cannot invite yourself';
  end if;

  if invitation_response_window_minutes not between 5 and 10080 then
    raise exception 'Invitation response window must be between 5 and 10080 minutes';
  end if;

  select *
  into booking_record
  from public.bookings
  where id = target_booking_id
  for update;

  if not found then
    raise exception 'Booking % not found', target_booking_id;
  end if;

  if booking_record.starts_at <= timezone('utc', now()) then
    raise exception 'Booking % has already started', target_booking_id;
  end if;

  if booking_record.status <> 'pending'::public.booking_status or booking_record.opponent_user_id is not null then
    raise exception 'Booking % is not awaiting invitations', target_booking_id;
  end if;

  if actor_id <> booking_record.created_by and not public.is_tennis_center_manager(booking_record.center_id) then
    raise exception 'You are not allowed to invite players to this booking';
  end if;

  if exists (
    select 1
    from public.booking_invitations
    where booking_id = target_booking_id
      and invitee_user_id = target_invitee_user_id
  ) then
    raise exception 'This player is already in the invitation queue for booking %', target_booking_id;
  end if;

  next_priority := coalesce((
    select max(priority)
    from public.booking_invitations
    where booking_id = target_booking_id
  ), 0) + 1;

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
    target_booking_id,
    booking_record.created_by,
    target_invitee_user_id,
    next_priority,
    'queued'::public.invitation_status,
    nullif(btrim(invitation_message), ''),
    invitation_response_window_minutes
  )
  returning * into created_invitation;

  update public.bookings
  set hold_expires_at = null,
      updated_at = timezone('utc', now())
  where id = target_booking_id;

  activated_id := public.activate_next_booking_invitation(target_booking_id);

  select *
  into created_invitation
  from public.booking_invitations
  where id = created_invitation.id;

  return query
  select created_invitation.id, created_invitation.status, created_invitation.priority, activated_id;
end;
$$;

revoke all on function public.queue_booking_invitation(
  uuid,
  uuid,
  text,
  integer
) from public, anon;
grant execute on function public.queue_booking_invitation(
  uuid,
  uuid,
  text,
  integer
) to authenticated;

create or replace function public.cancel_booking_invitation(target_invitation_id uuid)
returns table (
  booking_id uuid,
  cancelled_invitation_id uuid,
  next_invitation_id uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  invitation_record public.booking_invitations%rowtype;
  booking_record public.bookings%rowtype;
  activated_id uuid := null;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into invitation_record
  from public.booking_invitations
  where id = target_invitation_id
  for update;

  if not found then
    raise exception 'Invitation % not found', target_invitation_id;
  end if;

  select *
  into booking_record
  from public.bookings
  where id = invitation_record.booking_id
  for update;

  if not found then
    raise exception 'Booking % not found', invitation_record.booking_id;
  end if;

  if actor_id not in (invitation_record.creator_user_id, invitation_record.invitee_user_id)
     and not public.is_tennis_center_manager(booking_record.center_id) then
    raise exception 'You are not allowed to cancel this invitation';
  end if;

  if invitation_record.status not in ('queued'::public.invitation_status, 'pending'::public.invitation_status) then
    return query
    select invitation_record.booking_id, invitation_record.id, null::uuid;
    return;
  end if;

  update public.booking_invitations
  set status = 'cancelled'::public.invitation_status,
      responded_at = coalesce(responded_at, timezone('utc', now())),
      updated_at = timezone('utc', now())
  where id = invitation_record.id;

  if booking_record.status = 'pending'::public.booking_status and booking_record.opponent_user_id is null then
    activated_id := public.activate_next_booking_invitation(booking_record.id);
  end if;

  return query
  select invitation_record.booking_id, invitation_record.id, activated_id;
end;
$$;

revoke all on function public.cancel_booking_invitation(uuid) from public, anon;
grant execute on function public.cancel_booking_invitation(uuid) to authenticated;

create or replace function public.cancel_booking_workflow(
  target_booking_id uuid,
  requested_cancel_reason text default null
)
returns table (
  booking_id uuid,
  booking_status public.booking_status
)
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_id uuid := auth.uid();
  booking_record public.bookings%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required';
  end if;

  select *
  into booking_record
  from public.bookings
  where id = target_booking_id
  for update;

  if not found then
    raise exception 'Booking % not found', target_booking_id;
  end if;

  if actor_id not in (booking_record.created_by, booking_record.opponent_user_id)
     and not public.is_tennis_center_manager(booking_record.center_id) then
    raise exception 'You are not allowed to cancel booking %', target_booking_id;
  end if;

  if booking_record.status = 'cancelled'::public.booking_status then
    return query
    select booking_record.id, booking_record.status;
    return;
  end if;

  if booking_record.status in ('completed'::public.booking_status, 'no_show'::public.booking_status) then
    raise exception 'Booking % can no longer be cancelled', target_booking_id;
  end if;

  update public.bookings
  set status = 'cancelled'::public.booking_status,
      cancel_reason = coalesce(nullif(btrim(requested_cancel_reason), ''), cancel_reason, 'user_cancelled'),
      cancelled_at = coalesce(cancelled_at, timezone('utc', now())),
      hold_expires_at = null,
      updated_at = timezone('utc', now())
  where id = booking_record.id;

  update public.booking_invitations
  set status = 'cancelled'::public.invitation_status,
      responded_at = coalesce(responded_at, timezone('utc', now())),
      updated_at = timezone('utc', now())
  where booking_id = booking_record.id
    and status in ('queued'::public.invitation_status, 'pending'::public.invitation_status, 'accepted'::public.invitation_status);

  return query
  select b.id, b.status
  from public.bookings b
  where b.id = booking_record.id;
end;
$$;

revoke all on function public.cancel_booking_workflow(uuid, text) from public, anon;
grant execute on function public.cancel_booking_workflow(uuid, text) to authenticated;

drop policy if exists "bookings_creator_insert" on public.bookings;
drop policy if exists "bookings_owner_delete" on public.bookings;
drop policy if exists "booking_invitations_creator_insert" on public.booking_invitations;
drop policy if exists "booking_invitations_access_update" on public.booking_invitations;
drop policy if exists "booking_invitations_creator_delete" on public.booking_invitations;

select cron.schedule(
  'expire-stale-booking-work',
  '*/5 * * * *',
  'select public.expire_stale_booking_work();'
);
