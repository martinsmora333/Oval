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

  update public.booking_invitations bi
  set status = 'cancelled'::public.invitation_status,
      responded_at = coalesce(bi.responded_at, timezone('utc', now())),
      updated_at = timezone('utc', now())
  where bi.booking_id = booking_record.id
    and bi.status in (
      'queued'::public.invitation_status,
      'pending'::public.invitation_status,
      'accepted'::public.invitation_status
    );

  return query
  select b.id, b.status
  from public.bookings b
  where b.id = booking_record.id;
end;
$$;

revoke all on function public.cancel_booking_workflow(uuid, text) from public, anon;
grant execute on function public.cancel_booking_workflow(uuid, text) to authenticated;
