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

    update public.booking_invitations bi
    set status = 'cancelled'::public.invitation_status,
        responded_at = coalesce(bi.responded_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where bi.booking_id = invitation_record.booking_id
      and bi.id <> invitation_record.id
      and bi.status in (
        'queued'::public.invitation_status,
        'pending'::public.invitation_status
      );

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
