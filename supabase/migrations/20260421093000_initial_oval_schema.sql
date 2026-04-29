create schema if not exists extensions;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists citext with schema extensions;
create extension if not exists btree_gist with schema extensions;
create extension if not exists pg_trgm with schema extensions;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'player_level') then
    create type public.player_level as enum ('beginner', 'intermediate', 'advanced', 'pro');
  end if;
  if not exists (select 1 from pg_type where typname = 'app_user_type') then
    create type public.app_user_type as enum ('player', 'court_manager');
  end if;
  if not exists (select 1 from pg_type where typname = 'center_manager_role') then
    create type public.center_manager_role as enum ('owner', 'manager', 'staff');
  end if;
  if not exists (select 1 from pg_type where typname = 'court_surface') then
    create type public.court_surface as enum ('clay', 'hard', 'grass', 'carpet');
  end if;
  if not exists (select 1 from pg_type where typname = 'court_status') then
    create type public.court_status as enum ('active', 'inactive', 'maintenance');
  end if;
  if not exists (select 1 from pg_type where typname = 'booking_status') then
    create type public.booking_status as enum ('draft', 'pending', 'confirmed', 'cancelled', 'completed', 'no_show');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_status') then
    create type public.payment_status as enum ('pending', 'partial', 'complete', 'refunded', 'failed');
  end if;
  if not exists (select 1 from pg_type where typname = 'invitation_status') then
    create type public.invitation_status as enum ('queued', 'pending', 'accepted', 'declined', 'expired', 'cancelled', 'skipped');
  end if;
  if not exists (select 1 from pg_type where typname = 'booking_payment_status') then
    create type public.booking_payment_status as enum ('pending', 'processing', 'complete', 'refunded', 'failed');
  end if;
  if not exists (select 1 from pg_type where typname = 'court_block_kind') then
    create type public.court_block_kind as enum ('maintenance', 'special_event', 'blackout');
  end if;
end
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create or replace function public.try_parse_uuid(value text)
returns uuid
language plpgsql
immutable
as $$
begin
  return value::uuid;
exception
  when others then
    return null;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  legacy_firebase_uid text unique,
  email extensions.citext not null unique,
  phone_number text,
  preferred_play_times text[] not null default '{}'::text[],
  preferred_locations text[] not null default '{}'::text[],
  stripe_customer_id text unique,
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.public_profiles (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  display_name text not null check (btrim(display_name) <> ''),
  player_level public.player_level not null default 'intermediate',
  user_type public.app_user_type not null default 'player',
  profile_image_path text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.tennis_centers (
  id uuid primary key default extensions.gen_random_uuid(),
  legacy_firebase_id text unique,
  name text not null check (btrim(name) <> ''),
  slug text,
  description text not null default '',
  phone_number text,
  email extensions.citext,
  website text,
  street text not null default '',
  city text not null default '',
  state text not null default '',
  postal_code text not null default '',
  country text not null default '',
  latitude double precision,
  longitude double precision,
  is_active boolean not null default true,
  rating_average numeric(3, 2) not null default 0 check (rating_average between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists tennis_centers_slug_key
on public.tennis_centers (slug)
where slug is not null;

create index if not exists tennis_centers_name_idx
on public.tennis_centers using gin (to_tsvector('simple', coalesce(name, '')));

create index if not exists tennis_centers_location_idx
on public.tennis_centers (latitude, longitude);

create table if not exists public.tennis_center_billing (
  center_id uuid primary key references public.tennis_centers (id) on delete cascade,
  stripe_account_id text unique,
  onboarding_completed boolean not null default false,
  payouts_enabled boolean not null default false,
  charges_enabled boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.tennis_center_managers (
  center_id uuid not null references public.tennis_centers (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role public.center_manager_role not null default 'manager',
  created_at timestamptz not null default timezone('utc', now()),
  primary key (center_id, user_id)
);

create table if not exists public.center_operating_hours (
  center_id uuid not null references public.tennis_centers (id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  opens_at time,
  closes_at time,
  is_closed boolean not null default false,
  primary key (center_id, day_of_week),
  check (
    (is_closed and opens_at is null and closes_at is null)
    or (
      not is_closed
      and opens_at is not null
      and closes_at is not null
      and closes_at > opens_at
    )
  )
);

create table if not exists public.courts (
  id uuid primary key default extensions.gen_random_uuid(),
  center_id uuid not null references public.tennis_centers (id) on delete cascade,
  legacy_firebase_id text,
  name text not null check (btrim(name) <> ''),
  surface public.court_surface not null default 'hard',
  indoor boolean not null default false,
  has_lighting boolean not null default false,
  hourly_rate numeric(10, 2) not null check (hourly_rate >= 0),
  default_duration_minutes integer not null default 60 check (default_duration_minutes > 0 and default_duration_minutes % 15 = 0),
  status public.court_status not null default 'active',
  features text[] not null default '{}'::text[],
  rating_average numeric(3, 2) not null default 0 check (rating_average between 0 and 5),
  rating_count integer not null default 0 check (rating_count >= 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (center_id, name)
);

create unique index if not exists courts_center_legacy_id_key
on public.courts (center_id, legacy_firebase_id)
where legacy_firebase_id is not null;

create table if not exists public.court_operating_hours (
  court_id uuid not null references public.courts (id) on delete cascade,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  opens_at time,
  closes_at time,
  is_closed boolean not null default false,
  primary key (court_id, day_of_week),
  check (
    (is_closed and opens_at is null and closes_at is null)
    or (
      not is_closed
      and opens_at is not null
      and closes_at is not null
      and closes_at > opens_at
    )
  )
);

create table if not exists public.court_pricing_rules (
  id uuid primary key default extensions.gen_random_uuid(),
  court_id uuid not null references public.courts (id) on delete cascade,
  day_of_week smallint check (day_of_week between 0 and 6),
  starts_at time,
  ends_at time,
  price numeric(10, 2) not null check (price >= 0),
  priority smallint not null default 100,
  active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  check (
    (starts_at is null and ends_at is null)
    or (
      starts_at is not null
      and ends_at is not null
      and ends_at > starts_at
    )
  )
);

create table if not exists public.court_blocks (
  id uuid primary key default extensions.gen_random_uuid(),
  court_id uuid not null references public.courts (id) on delete cascade,
  block_kind public.court_block_kind not null default 'maintenance',
  label text,
  notes text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (ends_at > starts_at)
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'court_blocks_no_overlap'
  ) then
    alter table public.court_blocks
      add constraint court_blocks_no_overlap
      exclude using gist (
        court_id with =,
        tstzrange(starts_at, ends_at, '[)') with &&
      );
  end if;
end
$$;

create table if not exists public.tennis_center_images (
  id uuid primary key default extensions.gen_random_uuid(),
  center_id uuid not null references public.tennis_centers (id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  alt_text text,
  created_at timestamptz not null default timezone('utc', now()),
  unique (center_id, storage_path)
);

create table if not exists public.court_images (
  id uuid primary key default extensions.gen_random_uuid(),
  court_id uuid not null references public.courts (id) on delete cascade,
  storage_path text not null,
  sort_order integer not null default 0,
  alt_text text,
  created_at timestamptz not null default timezone('utc', now()),
  unique (court_id, storage_path)
);

create table if not exists public.bookings (
  id uuid primary key default extensions.gen_random_uuid(),
  legacy_firebase_id text unique,
  center_id uuid not null references public.tennis_centers (id) on delete restrict,
  court_id uuid not null references public.courts (id) on delete restrict,
  created_by uuid not null references public.profiles (id) on delete restrict,
  opponent_user_id uuid references public.profiles (id) on delete set null,
  status public.booking_status not null default 'pending',
  payment_status public.payment_status not null default 'pending',
  total_amount numeric(10, 2) not null default 0 check (total_amount >= 0),
  amount_per_player numeric(10, 2) not null default 0 check (amount_per_player >= 0),
  currency text not null default 'AUD' check (char_length(currency) = 3),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  booking_window tstzrange generated always as (tstzrange(starts_at, ends_at, '[)')) stored,
  notes text,
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (ends_at > starts_at),
  check (total_amount >= amount_per_player)
);

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'bookings_no_overlapping_active_slots'
  ) then
    alter table public.bookings
      add constraint bookings_no_overlapping_active_slots
      exclude using gist (
        court_id with =,
        booking_window with &&
      )
      where (status in ('pending'::public.booking_status, 'confirmed'::public.booking_status));
  end if;
end
$$;

create index if not exists bookings_center_time_idx
on public.bookings (center_id, starts_at);

create index if not exists bookings_creator_idx
on public.bookings (created_by, starts_at desc);

create index if not exists bookings_opponent_idx
on public.bookings (opponent_user_id, starts_at desc)
where opponent_user_id is not null;

create table if not exists public.booking_invitations (
  id uuid primary key default extensions.gen_random_uuid(),
  booking_id uuid not null references public.bookings (id) on delete cascade,
  creator_user_id uuid not null references public.profiles (id) on delete cascade,
  invitee_user_id uuid not null references public.profiles (id) on delete cascade,
  priority integer not null check (priority > 0),
  status public.invitation_status not null default 'queued',
  message text,
  activated_at timestamptz,
  expires_at timestamptz,
  responded_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check (creator_user_id <> invitee_user_id),
  unique (booking_id, invitee_user_id),
  unique (booking_id, priority)
);

create unique index if not exists booking_invitations_one_active_pending_idx
on public.booking_invitations (booking_id)
where status = 'pending'::public.invitation_status;

create unique index if not exists booking_invitations_one_accepted_idx
on public.booking_invitations (booking_id)
where status = 'accepted'::public.invitation_status;

create table if not exists public.booking_payments (
  id uuid primary key default extensions.gen_random_uuid(),
  booking_id uuid not null references public.bookings (id) on delete cascade,
  payer_user_id uuid not null references public.profiles (id) on delete cascade,
  amount numeric(10, 2) not null check (amount >= 0),
  currency text not null default 'AUD' check (char_length(currency) = 3),
  status public.booking_payment_status not null default 'pending',
  stripe_payment_intent_id text,
  stripe_charge_id text,
  refunded_amount numeric(10, 2) not null default 0 check (refunded_amount >= 0 and refunded_amount <= amount),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (booking_id, payer_user_id)
);

create table if not exists public.user_contacts (
  user_id uuid not null references public.profiles (id) on delete cascade,
  contact_user_id uuid not null references public.profiles (id) on delete cascade,
  priority_rank integer,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, contact_user_id),
  check (user_id <> contact_user_id)
);

create unique index if not exists user_contacts_priority_rank_key
on public.user_contacts (user_id, priority_rank)
where priority_rank is not null;

create table if not exists public.user_saved_payment_methods (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  provider text not null default 'stripe',
  provider_payment_method_id text not null,
  brand text,
  last4 text,
  exp_month integer check (exp_month between 1 and 12),
  exp_year integer,
  is_default boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (user_id, provider, provider_payment_method_id)
);

create unique index if not exists user_saved_payment_methods_one_default_idx
on public.user_saved_payment_methods (user_id)
where is_default;

create or replace function public.is_tennis_center_manager(target_center_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select exists (
        select 1
        from public.tennis_center_managers m
        where m.center_id = target_center_id
          and m.user_id = auth.uid()
      )
    ),
    false
  );
$$;

create or replace function public.is_tennis_center_owner(target_center_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select exists (
        select 1
        from public.tennis_center_managers m
        where m.center_id = target_center_id
          and m.user_id = auth.uid()
          and m.role = 'owner'::public.center_manager_role
      )
    ),
    false
  );
$$;

create or replace function public.can_manage_court(target_court_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.courts c
    where c.id = target_court_id
      and public.is_tennis_center_manager(c.center_id)
  );
$$;

create or replace function public.can_access_booking(target_booking_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.bookings b
    where b.id = target_booking_id
      and (
        b.created_by = auth.uid()
        or b.opponent_user_id = auth.uid()
        or public.is_tennis_center_manager(b.center_id)
      )
  );
$$;

create or replace function public.search_player_directory(search_term text, limit_count integer default 20)
returns table (
  user_id uuid,
  display_name text,
  email extensions.citext,
  player_level public.player_level,
  user_type public.app_user_type,
  profile_image_path text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    pp.user_id,
    pp.display_name,
    p.email,
    pp.player_level,
    pp.user_type,
    pp.profile_image_path
  from public.public_profiles pp
  join public.profiles p
    on p.id = pp.user_id
  where auth.uid() is not null
    and (
      pp.display_name ilike '%' || btrim(coalesce(search_term, '')) || '%'
      or p.email::text ilike '%' || btrim(coalesce(search_term, '')) || '%'
    )
  order by
    case
      when lower(pp.display_name) = lower(btrim(coalesce(search_term, ''))) then 0
      else 1
    end,
    pp.display_name
  limit least(greatest(coalesce(limit_count, 20), 1), 50);
$$;

grant execute on function public.search_player_directory(text, integer) to authenticated;

create or replace function public.sync_profile_from_auth()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update
    set email = excluded.email,
        updated_at = timezone('utc', now());

  insert into public.public_profiles (user_id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(coalesce(new.email, ''), '@', 1), 'Player')
  )
  on conflict (user_id) do update
    set display_name = excluded.display_name,
        updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert or update of email, raw_user_meta_data
on auth.users
for each row
execute function public.sync_profile_from_auth();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists public_profiles_set_updated_at on public.public_profiles;
create trigger public_profiles_set_updated_at
before update on public.public_profiles
for each row
execute function public.set_updated_at();

drop trigger if exists tennis_centers_set_updated_at on public.tennis_centers;
create trigger tennis_centers_set_updated_at
before update on public.tennis_centers
for each row
execute function public.set_updated_at();

drop trigger if exists tennis_center_billing_set_updated_at on public.tennis_center_billing;
create trigger tennis_center_billing_set_updated_at
before update on public.tennis_center_billing
for each row
execute function public.set_updated_at();

drop trigger if exists courts_set_updated_at on public.courts;
create trigger courts_set_updated_at
before update on public.courts
for each row
execute function public.set_updated_at();

drop trigger if exists court_blocks_set_updated_at on public.court_blocks;
create trigger court_blocks_set_updated_at
before update on public.court_blocks
for each row
execute function public.set_updated_at();

drop trigger if exists bookings_set_updated_at on public.bookings;
create trigger bookings_set_updated_at
before update on public.bookings
for each row
execute function public.set_updated_at();

drop trigger if exists booking_invitations_set_updated_at on public.booking_invitations;
create trigger booking_invitations_set_updated_at
before update on public.booking_invitations
for each row
execute function public.set_updated_at();

drop trigger if exists booking_payments_set_updated_at on public.booking_payments;
create trigger booking_payments_set_updated_at
before update on public.booking_payments
for each row
execute function public.set_updated_at();

drop trigger if exists user_contacts_set_updated_at on public.user_contacts;
create trigger user_contacts_set_updated_at
before update on public.user_contacts
for each row
execute function public.set_updated_at();

drop trigger if exists user_saved_payment_methods_set_updated_at on public.user_saved_payment_methods;
create trigger user_saved_payment_methods_set_updated_at
before update on public.user_saved_payment_methods
for each row
execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.public_profiles enable row level security;
alter table public.tennis_centers enable row level security;
alter table public.tennis_center_billing enable row level security;
alter table public.tennis_center_managers enable row level security;
alter table public.center_operating_hours enable row level security;
alter table public.courts enable row level security;
alter table public.court_operating_hours enable row level security;
alter table public.court_pricing_rules enable row level security;
alter table public.court_blocks enable row level security;
alter table public.tennis_center_images enable row level security;
alter table public.court_images enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_invitations enable row level security;
alter table public.booking_payments enable row level security;
alter table public.user_contacts enable row level security;
alter table public.user_saved_payment_methods enable row level security;

drop policy if exists "profiles_self_select" on public.profiles;
create policy "profiles_self_select"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "profiles_self_insert" on public.profiles;
create policy "profiles_self_insert"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists "profiles_self_update" on public.profiles;
create policy "profiles_self_update"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "public_profiles_directory_read" on public.public_profiles;
create policy "public_profiles_directory_read"
on public.public_profiles
for select
to authenticated
using (true);

drop policy if exists "public_profiles_self_insert" on public.public_profiles;
create policy "public_profiles_self_insert"
on public.public_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "public_profiles_self_update" on public.public_profiles;
create policy "public_profiles_self_update"
on public.public_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "tennis_centers_public_read" on public.tennis_centers;
create policy "tennis_centers_public_read"
on public.tennis_centers
for select
to public
using (true);

drop policy if exists "tennis_centers_creator_insert" on public.tennis_centers;
create policy "tennis_centers_creator_insert"
on public.tennis_centers
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "tennis_centers_manager_update" on public.tennis_centers;
create policy "tennis_centers_manager_update"
on public.tennis_centers
for update
to authenticated
using (public.is_tennis_center_manager(id))
with check (public.is_tennis_center_manager(id));

drop policy if exists "tennis_centers_manager_delete" on public.tennis_centers;
create policy "tennis_centers_manager_delete"
on public.tennis_centers
for delete
to authenticated
using (public.is_tennis_center_owner(id));

drop policy if exists "tennis_center_billing_manager_read" on public.tennis_center_billing;
create policy "tennis_center_billing_manager_read"
on public.tennis_center_billing
for select
to authenticated
using (public.is_tennis_center_manager(center_id));

drop policy if exists "tennis_center_billing_manager_write" on public.tennis_center_billing;
create policy "tennis_center_billing_manager_write"
on public.tennis_center_billing
for all
to authenticated
using (
  public.is_tennis_center_manager(center_id)
  or exists (
    select 1
    from public.tennis_centers c
    where c.id = center_id
      and c.created_by = auth.uid()
  )
)
with check (
  public.is_tennis_center_manager(center_id)
  or exists (
    select 1
    from public.tennis_centers c
    where c.id = center_id
      and c.created_by = auth.uid()
  )
);

drop policy if exists "tennis_center_managers_read" on public.tennis_center_managers;
create policy "tennis_center_managers_read"
on public.tennis_center_managers
for select
to authenticated
using (auth.uid() = user_id or public.is_tennis_center_manager(center_id));

drop policy if exists "tennis_center_managers_insert" on public.tennis_center_managers;
create policy "tennis_center_managers_insert"
on public.tennis_center_managers
for insert
to authenticated
with check (
  (
    auth.uid() = user_id
    and role = 'owner'::public.center_manager_role
    and exists (
      select 1
      from public.tennis_centers c
      where c.id = center_id
        and c.created_by = auth.uid()
    )
  )
  or public.is_tennis_center_owner(center_id)
);

drop policy if exists "tennis_center_managers_update" on public.tennis_center_managers;
create policy "tennis_center_managers_update"
on public.tennis_center_managers
for update
to authenticated
using (public.is_tennis_center_owner(center_id))
with check (public.is_tennis_center_owner(center_id));

drop policy if exists "tennis_center_managers_delete" on public.tennis_center_managers;
create policy "tennis_center_managers_delete"
on public.tennis_center_managers
for delete
to authenticated
using (public.is_tennis_center_owner(center_id));

drop policy if exists "center_operating_hours_public_read" on public.center_operating_hours;
create policy "center_operating_hours_public_read"
on public.center_operating_hours
for select
to public
using (true);

drop policy if exists "center_operating_hours_manager_write" on public.center_operating_hours;
create policy "center_operating_hours_manager_write"
on public.center_operating_hours
for all
to authenticated
using (public.is_tennis_center_manager(center_id))
with check (public.is_tennis_center_manager(center_id));

drop policy if exists "courts_public_read" on public.courts;
create policy "courts_public_read"
on public.courts
for select
to public
using (true);

drop policy if exists "courts_manager_write" on public.courts;
create policy "courts_manager_write"
on public.courts
for all
to authenticated
using (public.is_tennis_center_manager(center_id))
with check (public.is_tennis_center_manager(center_id));

drop policy if exists "court_operating_hours_public_read" on public.court_operating_hours;
create policy "court_operating_hours_public_read"
on public.court_operating_hours
for select
to public
using (true);

drop policy if exists "court_operating_hours_manager_write" on public.court_operating_hours;
create policy "court_operating_hours_manager_write"
on public.court_operating_hours
for all
to authenticated
using (public.can_manage_court(court_id))
with check (public.can_manage_court(court_id));

drop policy if exists "court_pricing_rules_public_read" on public.court_pricing_rules;
create policy "court_pricing_rules_public_read"
on public.court_pricing_rules
for select
to public
using (true);

drop policy if exists "court_pricing_rules_manager_write" on public.court_pricing_rules;
create policy "court_pricing_rules_manager_write"
on public.court_pricing_rules
for all
to authenticated
using (public.can_manage_court(court_id))
with check (public.can_manage_court(court_id));

drop policy if exists "court_blocks_public_read" on public.court_blocks;
create policy "court_blocks_public_read"
on public.court_blocks
for select
to public
using (true);

drop policy if exists "court_blocks_manager_write" on public.court_blocks;
create policy "court_blocks_manager_write"
on public.court_blocks
for all
to authenticated
using (public.can_manage_court(court_id))
with check (public.can_manage_court(court_id));

drop policy if exists "tennis_center_images_public_read" on public.tennis_center_images;
create policy "tennis_center_images_public_read"
on public.tennis_center_images
for select
to public
using (true);

drop policy if exists "tennis_center_images_manager_write" on public.tennis_center_images;
create policy "tennis_center_images_manager_write"
on public.tennis_center_images
for all
to authenticated
using (public.is_tennis_center_manager(center_id))
with check (public.is_tennis_center_manager(center_id));

drop policy if exists "court_images_public_read" on public.court_images;
create policy "court_images_public_read"
on public.court_images
for select
to public
using (true);

drop policy if exists "court_images_manager_write" on public.court_images;
create policy "court_images_manager_write"
on public.court_images
for all
to authenticated
using (public.can_manage_court(court_id))
with check (public.can_manage_court(court_id));

drop policy if exists "bookings_access_read" on public.bookings;
create policy "bookings_access_read"
on public.bookings
for select
to authenticated
using (
  created_by = auth.uid()
  or opponent_user_id = auth.uid()
  or public.is_tennis_center_manager(center_id)
);

drop policy if exists "bookings_creator_insert" on public.bookings;
create policy "bookings_creator_insert"
on public.bookings
for insert
to authenticated
with check (created_by = auth.uid());

drop policy if exists "bookings_access_update" on public.bookings;
create policy "bookings_access_update"
on public.bookings
for update
to authenticated
using (
  created_by = auth.uid()
  or opponent_user_id = auth.uid()
  or public.is_tennis_center_manager(center_id)
)
with check (
  created_by = auth.uid()
  or opponent_user_id = auth.uid()
  or public.is_tennis_center_manager(center_id)
);

drop policy if exists "bookings_owner_delete" on public.bookings;
create policy "bookings_owner_delete"
on public.bookings
for delete
to authenticated
using (
  created_by = auth.uid()
  or public.is_tennis_center_manager(center_id)
);

drop policy if exists "booking_invitations_access_read" on public.booking_invitations;
create policy "booking_invitations_access_read"
on public.booking_invitations
for select
to authenticated
using (
  creator_user_id = auth.uid()
  or invitee_user_id = auth.uid()
  or public.can_access_booking(booking_id)
);

drop policy if exists "booking_invitations_creator_insert" on public.booking_invitations;
create policy "booking_invitations_creator_insert"
on public.booking_invitations
for insert
to authenticated
with check (
  creator_user_id = auth.uid()
  and exists (
    select 1
    from public.bookings b
    where b.id = booking_id
      and b.created_by = auth.uid()
  )
);

drop policy if exists "booking_invitations_access_update" on public.booking_invitations;
create policy "booking_invitations_access_update"
on public.booking_invitations
for update
to authenticated
using (
  creator_user_id = auth.uid()
  or invitee_user_id = auth.uid()
  or public.can_access_booking(booking_id)
)
with check (
  creator_user_id = auth.uid()
  or invitee_user_id = auth.uid()
  or public.can_access_booking(booking_id)
);

drop policy if exists "booking_invitations_creator_delete" on public.booking_invitations;
create policy "booking_invitations_creator_delete"
on public.booking_invitations
for delete
to authenticated
using (
  creator_user_id = auth.uid()
  or public.can_access_booking(booking_id)
);

drop policy if exists "booking_payments_access_read" on public.booking_payments;
create policy "booking_payments_access_read"
on public.booking_payments
for select
to authenticated
using (
  payer_user_id = auth.uid()
  or public.can_access_booking(booking_id)
);

drop policy if exists "booking_payments_access_write" on public.booking_payments;
create policy "booking_payments_access_write"
on public.booking_payments
for all
to authenticated
using (
  payer_user_id = auth.uid()
  or public.can_access_booking(booking_id)
)
with check (
  payer_user_id = auth.uid()
  or public.can_access_booking(booking_id)
);

drop policy if exists "user_contacts_self_read" on public.user_contacts;
create policy "user_contacts_self_read"
on public.user_contacts
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "user_contacts_self_write" on public.user_contacts;
create policy "user_contacts_self_write"
on public.user_contacts
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "user_saved_payment_methods_self_read" on public.user_saved_payment_methods;
create policy "user_saved_payment_methods_self_read"
on public.user_saved_payment_methods
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "user_saved_payment_methods_self_write" on public.user_saved_payment_methods;
create policy "user_saved_payment_methods_self_write"
on public.user_saved_payment_methods
for all
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

insert into storage.buckets (id, name, public)
values
  ('profile-pictures', 'profile-pictures', true),
  ('tennis-center-images', 'tennis-center-images', true),
  ('court-images', 'court-images', true)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "profile_pictures_public_read" on storage.objects;
create policy "profile_pictures_public_read"
on storage.objects
for select
to public
using (bucket_id = 'profile-pictures');

drop policy if exists "profile_pictures_owner_insert" on storage.objects;
create policy "profile_pictures_owner_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "profile_pictures_owner_update" on storage.objects;
create policy "profile_pictures_owner_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "profile_pictures_owner_delete" on storage.objects;
create policy "profile_pictures_owner_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-pictures'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "tennis_center_images_public_read" on storage.objects;
create policy "tennis_center_images_public_read"
on storage.objects
for select
to public
using (bucket_id = 'tennis-center-images');

drop policy if exists "tennis_center_images_manager_insert" on storage.objects;
create policy "tennis_center_images_manager_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'tennis-center-images'
  and public.is_tennis_center_manager(public.try_parse_uuid((storage.foldername(name))[1]))
);

drop policy if exists "tennis_center_images_manager_update" on storage.objects;
create policy "tennis_center_images_manager_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'tennis-center-images'
  and public.is_tennis_center_manager(public.try_parse_uuid((storage.foldername(name))[1]))
)
with check (
  bucket_id = 'tennis-center-images'
  and public.is_tennis_center_manager(public.try_parse_uuid((storage.foldername(name))[1]))
);

drop policy if exists "tennis_center_images_manager_delete" on storage.objects;
create policy "tennis_center_images_manager_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'tennis-center-images'
  and public.is_tennis_center_manager(public.try_parse_uuid((storage.foldername(name))[1]))
);

drop policy if exists "court_images_public_read" on storage.objects;
create policy "court_images_public_read"
on storage.objects
for select
to public
using (bucket_id = 'court-images');

drop policy if exists "court_images_manager_insert" on storage.objects;
create policy "court_images_manager_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'court-images'
  and public.can_manage_court(public.try_parse_uuid((storage.foldername(name))[1]))
);

drop policy if exists "court_images_manager_update" on storage.objects;
create policy "court_images_manager_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'court-images'
  and public.can_manage_court(public.try_parse_uuid((storage.foldername(name))[1]))
)
with check (
  bucket_id = 'court-images'
  and public.can_manage_court(public.try_parse_uuid((storage.foldername(name))[1]))
);

drop policy if exists "court_images_manager_delete" on storage.objects;
create policy "court_images_manager_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'court-images'
  and public.can_manage_court(public.try_parse_uuid((storage.foldername(name))[1]))
);
