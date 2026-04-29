alter table public.tennis_centers
  add column if not exists amenities text[] not null default '{}'::text[],
  add column if not exists timezone_name text not null default 'Australia/Brisbane';

create index if not exists tennis_centers_city_state_idx
on public.tennis_centers (city, state);

create index if not exists tennis_centers_name_trgm_idx
on public.tennis_centers using gin (name extensions.gin_trgm_ops);

alter table public.courts
  add column if not exists max_players integer not null default 2,
  add column if not exists booking_interval_minutes integer not null default 30,
  add column if not exists minimum_booking_minutes integer not null default 60,
  add column if not exists maximum_booking_minutes integer not null default 120,
  add column if not exists advance_booking_days integer not null default 30,
  add column if not exists minimum_notice_hours integer not null default 0;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'courts_max_players_check'
  ) then
    alter table public.courts
      add constraint courts_max_players_check
      check (max_players between 1 and 8);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'courts_booking_interval_minutes_check'
  ) then
    alter table public.courts
      add constraint courts_booking_interval_minutes_check
      check (booking_interval_minutes > 0 and booking_interval_minutes % 15 = 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'courts_minimum_booking_minutes_check'
  ) then
    alter table public.courts
      add constraint courts_minimum_booking_minutes_check
      check (minimum_booking_minutes > 0 and minimum_booking_minutes % 15 = 0);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'courts_maximum_booking_minutes_check'
  ) then
    alter table public.courts
      add constraint courts_maximum_booking_minutes_check
      check (
        maximum_booking_minutes >= minimum_booking_minutes
        and maximum_booking_minutes % 15 = 0
      );
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'courts_advance_booking_days_check'
  ) then
    alter table public.courts
      add constraint courts_advance_booking_days_check
      check (advance_booking_days between 0 and 365);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'courts_minimum_notice_hours_check'
  ) then
    alter table public.courts
      add constraint courts_minimum_notice_hours_check
      check (minimum_notice_hours between 0 and 720);
  end if;
end
$$;

create index if not exists courts_center_status_idx
on public.courts (center_id, status);

alter table public.bookings
  add column if not exists hold_expires_at timestamptz,
  add column if not exists cancelled_by uuid references public.profiles (id) on delete set null,
  add column if not exists cancel_reason text;

create index if not exists bookings_court_time_idx
on public.bookings (court_id, starts_at);

create index if not exists bookings_pending_hold_idx
on public.bookings (hold_expires_at)
where status = 'pending'::public.booking_status;

alter table public.booking_invitations
  add column if not exists response_window_minutes integer not null default 120;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'booking_invitations_response_window_minutes_check'
  ) then
    alter table public.booking_invitations
      add constraint booking_invitations_response_window_minutes_check
      check (response_window_minutes between 5 and 10080);
  end if;
end
$$;

create index if not exists booking_invitations_status_priority_idx
on public.booking_invitations (booking_id, status, priority);

create index if not exists booking_invitations_invitee_status_idx
on public.booking_invitations (invitee_user_id, status, created_at desc);

create index if not exists court_blocks_court_time_idx
on public.court_blocks (court_id, starts_at);

create index if not exists public_profiles_display_name_trgm_idx
on public.public_profiles using gin (display_name extensions.gin_trgm_ops);

create or replace function public.sync_profile_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  derived_display_name text;
begin
  derived_display_name := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
    'Player'
  );

  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update
    set email = coalesce(excluded.email, public.profiles.email),
        updated_at = timezone('utc', now());

  insert into public.public_profiles (user_id, display_name)
  values (new.id, derived_display_name)
  on conflict (user_id) do update
    set display_name = case
      when nullif(btrim(new.raw_user_meta_data ->> 'display_name'), '') is not null then excluded.display_name
      when nullif(btrim(public.public_profiles.display_name), '') is null then excluded.display_name
      else public.public_profiles.display_name
    end,
        updated_at = timezone('utc', now());

  return new;
end;
$$;

create or replace function public.provision_tennis_center_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.tennis_center_billing (center_id)
  values (new.id)
  on conflict (center_id) do nothing;

  if new.created_by is not null then
    insert into public.tennis_center_managers (center_id, user_id, role)
    values (new.id, new.created_by, 'owner')
    on conflict (center_id, user_id) do update
      set role = case
        when public.tennis_center_managers.role = 'owner'::public.center_manager_role then public.tennis_center_managers.role
        else excluded.role
      end;
  end if;

  return new;
end;
$$;

revoke all on function public.provision_tennis_center_defaults() from public, anon, authenticated;

drop trigger if exists tennis_centers_provision_defaults on public.tennis_centers;
create trigger tennis_centers_provision_defaults
after insert on public.tennis_centers
for each row
execute function public.provision_tennis_center_defaults();

create or replace function public.normalize_booking_state()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'pending'::public.booking_status and new.opponent_user_id is null then
    new.hold_expires_at := coalesce(new.hold_expires_at, timezone('utc', now()) + interval '2 hours');
  else
    new.hold_expires_at := null;
  end if;

  if new.status = 'confirmed'::public.booking_status and new.confirmed_at is null then
    new.confirmed_at := timezone('utc', now());
  end if;

  if new.status = 'cancelled'::public.booking_status and new.cancelled_at is null then
    new.cancelled_at := timezone('utc', now());
  end if;

  return new;
end;
$$;

drop trigger if exists bookings_normalize_state on public.bookings;
create trigger bookings_normalize_state
before insert or update on public.bookings
for each row
execute function public.normalize_booking_state();

create or replace function public.normalize_booking_invitation()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'queued'::public.invitation_status then
    new.activated_at := null;
    new.expires_at := null;
    if tg_op = 'INSERT' then
      new.responded_at := null;
    end if;
    return new;
  end if;

  if new.status = 'pending'::public.invitation_status then
    new.activated_at := coalesce(new.activated_at, timezone('utc', now()));
    new.expires_at := coalesce(
      new.expires_at,
      new.activated_at + make_interval(mins => new.response_window_minutes)
    );
    new.responded_at := null;
    return new;
  end if;

  if tg_op = 'UPDATE' and old.status is distinct from new.status and new.responded_at is null then
    new.responded_at := timezone('utc', now());
  end if;

  return new;
end;
$$;

drop trigger if exists booking_invitations_normalize_state on public.booking_invitations;
create trigger booking_invitations_normalize_state
before insert or update on public.booking_invitations
for each row
execute function public.normalize_booking_invitation();

create or replace function public.ensure_single_default_payment_method()
returns trigger
language plpgsql
as $$
begin
  if new.is_default then
    update public.user_saved_payment_methods
    set is_default = false,
        updated_at = timezone('utc', now())
    where user_id = new.user_id
      and id <> new.id
      and is_default;
  end if;

  return new;
end;
$$;

revoke all on function public.ensure_single_default_payment_method() from public, anon, authenticated;

drop trigger if exists user_saved_payment_methods_single_default on public.user_saved_payment_methods;
create trigger user_saved_payment_methods_single_default
before insert or update on public.user_saved_payment_methods
for each row
execute function public.ensure_single_default_payment_method();

create or replace function public.activate_next_booking_invitation(target_booking_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  next_invitation_id uuid;
  booking_record public.bookings%rowtype;
begin
  if target_booking_id is null then
    return null;
  end if;

  select *
  into booking_record
  from public.bookings
  where id = target_booking_id
  for update;

  if not found then
    return null;
  end if;

  if booking_record.status <> 'pending'::public.booking_status or booking_record.opponent_user_id is not null then
    return null;
  end if;

  if exists (
    select 1
    from public.booking_invitations
    where booking_id = target_booking_id
      and status in ('pending'::public.invitation_status, 'accepted'::public.invitation_status)
  ) then
    return null;
  end if;

  select bi.id
  into next_invitation_id
  from public.booking_invitations bi
  where bi.booking_id = target_booking_id
    and bi.status = 'queued'::public.invitation_status
  order by bi.priority
  limit 1
  for update skip locked;

  if next_invitation_id is null then
    update public.bookings
    set status = 'cancelled'::public.booking_status,
        cancel_reason = coalesce(cancel_reason, 'no_invitee_available'),
        cancelled_at = coalesce(cancelled_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where id = target_booking_id
      and status = 'pending'::public.booking_status
      and opponent_user_id is null;

    update public.booking_invitations
    set status = 'cancelled'::public.invitation_status,
        responded_at = coalesce(responded_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where booking_id = target_booking_id
      and status = 'queued'::public.invitation_status;

    return null;
  end if;

  update public.booking_invitations
  set status = 'pending'::public.invitation_status,
      activated_at = timezone('utc', now()),
      expires_at = timezone('utc', now()) + make_interval(mins => response_window_minutes),
      updated_at = timezone('utc', now())
  where id = next_invitation_id;

  return next_invitation_id;
end;
$$;

revoke all on function public.activate_next_booking_invitation(uuid) from public, anon, authenticated;

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

create or replace function public.expire_stale_booking_work()
returns table (
  expired_invitation_count integer,
  cancelled_booking_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  invitation_record record;
  booking_record record;
  expired_count integer := 0;
  cancelled_count integer := 0;
begin
  for invitation_record in
    select id, booking_id
    from public.booking_invitations
    where status = 'pending'::public.invitation_status
      and expires_at is not null
      and expires_at <= timezone('utc', now())
    for update skip locked
  loop
    update public.booking_invitations
    set status = 'expired'::public.invitation_status,
        responded_at = coalesce(responded_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where id = invitation_record.id;

    expired_count := expired_count + 1;
    perform public.activate_next_booking_invitation(invitation_record.booking_id);
  end loop;

  for booking_record in
    select id
    from public.bookings
    where status = 'pending'::public.booking_status
      and opponent_user_id is null
      and hold_expires_at is not null
      and hold_expires_at <= timezone('utc', now())
    for update skip locked
  loop
    update public.bookings
    set status = 'cancelled'::public.booking_status,
        cancel_reason = coalesce(cancel_reason, 'hold_expired'),
        cancelled_at = coalesce(cancelled_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where id = booking_record.id;

    update public.booking_invitations
    set status = case
      when status = 'pending'::public.invitation_status then 'expired'::public.invitation_status
      else 'cancelled'::public.invitation_status
    end,
        responded_at = coalesce(responded_at, timezone('utc', now())),
        updated_at = timezone('utc', now())
    where booking_id = booking_record.id
      and status in ('queued'::public.invitation_status, 'pending'::public.invitation_status);

    cancelled_count := cancelled_count + 1;
  end loop;

  return query
  select expired_count, cancelled_count;
end;
$$;

revoke all on function public.expire_stale_booking_work() from public, anon, authenticated;

create or replace function public.get_court_day_availability(
  target_court_id uuid,
  target_date date,
  requested_duration_minutes integer default null
)
returns table (
  slot_id text,
  slot_date date,
  starts_at timestamptz,
  ends_at timestamptz,
  start_time text,
  end_time text,
  status text,
  price numeric(10, 2),
  special_event boolean,
  max_players integer,
  booking_id uuid
)
language sql
stable
security definer
set search_path = public
as $$
  with court_config as (
    select
      c.id as court_id,
      c.center_id,
      tc.timezone_name,
      coalesce(requested_duration_minutes, c.default_duration_minutes) as duration_minutes,
      c.booking_interval_minutes,
      c.minimum_booking_minutes,
      c.maximum_booking_minutes,
      c.advance_booking_days,
      c.minimum_notice_hours,
      c.hourly_rate,
      c.max_players,
      c.status as court_status,
      tc.is_active as center_active
    from public.courts c
    join public.tennis_centers tc
      on tc.id = c.center_id
    where c.id = target_court_id
  ),
  day_config as (
    select
      cc.*,
      coalesce(coh.opens_at, ch.opens_at) as opens_at,
      coalesce(coh.closes_at, ch.closes_at) as closes_at,
      coalesce(coh.is_closed, ch.is_closed, true) as is_closed
    from court_config cc
    left join public.court_operating_hours coh
      on coh.court_id = cc.court_id
     and coh.day_of_week = extract(dow from target_date)::smallint
    left join public.center_operating_hours ch
      on ch.center_id = cc.center_id
     and ch.day_of_week = extract(dow from target_date)::smallint
  ),
  slot_series as (
    select
      dc.*,
      gs as local_start,
      gs + make_interval(mins => dc.duration_minutes) as local_end
    from day_config dc
    cross join lateral generate_series(
      target_date::timestamp + dc.opens_at,
      target_date::timestamp + dc.closes_at - make_interval(mins => dc.duration_minutes),
      make_interval(mins => dc.booking_interval_minutes)
    ) as gs
    where dc.center_active
      and dc.court_status = 'active'::public.court_status
      and not dc.is_closed
      and dc.opens_at is not null
      and dc.closes_at is not null
      and dc.duration_minutes between dc.minimum_booking_minutes and dc.maximum_booking_minutes
      and target_date <= ((timezone(dc.timezone_name, now()))::date + dc.advance_booking_days)
  ),
  priced_slots as (
    select
      ss.*,
      ss.local_start at time zone ss.timezone_name as starts_at,
      ss.local_end at time zone ss.timezone_name as ends_at,
      coalesce(
        (
          select pr.price
          from public.court_pricing_rules pr
          where pr.court_id = ss.court_id
            and pr.active
            and (pr.day_of_week is null or pr.day_of_week = extract(dow from target_date)::smallint)
            and (pr.starts_at is null or pr.starts_at <= ss.local_start::time)
            and (pr.ends_at is null or pr.ends_at >= ss.local_end::time)
          order by pr.priority asc, pr.price desc
          limit 1
        ),
        round((ss.hourly_rate * ss.duration_minutes::numeric) / 60, 2)
      )::numeric(10, 2) as slot_price
    from slot_series ss
    where ss.local_start at time zone ss.timezone_name >= timezone('utc', now()) + make_interval(hours => ss.minimum_notice_hours)
  ),
  slot_matches as (
    select
      ps.*,
      matched_booking.id as matched_booking_id,
      matched_booking.status as matched_booking_status,
      matched_block.block_kind
    from priced_slots ps
    left join lateral (
      select b.id, b.status
      from public.bookings b
      where b.court_id = ps.court_id
        and b.status in ('pending'::public.booking_status, 'confirmed'::public.booking_status)
        and tstzrange(b.starts_at, b.ends_at, '[)') && tstzrange(ps.starts_at, ps.ends_at, '[)')
      order by case when b.status = 'confirmed'::public.booking_status then 0 else 1 end
      limit 1
    ) as matched_booking on true
    left join lateral (
      select cb.block_kind
      from public.court_blocks cb
      where cb.court_id = ps.court_id
        and tstzrange(cb.starts_at, cb.ends_at, '[)') && tstzrange(ps.starts_at, ps.ends_at, '[)')
      order by case when cb.block_kind = 'special_event'::public.court_block_kind then 0 else 1 end
      limit 1
    ) as matched_block on true
  )
  select
    concat(target_court_id::text, ':', to_char(local_start, 'YYYY-MM-DD"T"HH24:MI')) as slot_id,
    target_date as slot_date,
    starts_at,
    ends_at,
    to_char(local_start, 'HH24:MI') as start_time,
    to_char(local_end, 'HH24:MI') as end_time,
    case
      when block_kind is not null then 'maintenance'
      when matched_booking_status = 'pending'::public.booking_status then 'pending'
      when matched_booking_status = 'confirmed'::public.booking_status then 'booked'
      else 'available'
    end as status,
    slot_price as price,
    (block_kind = 'special_event'::public.court_block_kind) as special_event,
    max_players,
    case
      when auth.uid() is not null then matched_booking_id
      else null::uuid
    end as booking_id
  from slot_matches
  order by starts_at;
$$;

revoke all on function public.get_court_day_availability(uuid, date, integer) from public, anon;
grant execute on function public.get_court_day_availability(uuid, date, integer) to authenticated;
