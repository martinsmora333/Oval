# Supabase Schema Notes

This project now uses a relational Supabase schema designed around the actual Oval domain instead of Firestore document mirrors.

## Core tables

- `public.profiles`: private user account data keyed to `auth.users`
- `public.public_profiles`: directory-safe profile data for search and contact flows
- `public.tennis_centers`: tennis centre records, address fields, geo coordinates, timezone, amenities
- `public.tennis_center_managers`: normalized manager membership instead of `managerIds` arrays
- `public.tennis_center_billing`: Stripe connected-account state for centres
- `public.center_operating_hours`: weekly centre opening hours
- `public.courts`: court configuration, booking cadence, pricing defaults, booking limits
- `public.court_operating_hours`: optional court-level opening-hour overrides
- `public.court_pricing_rules`: time-based pricing overrides
- `public.court_blocks`: maintenance, blackout, and special-event windows
- `public.bookings`: normalized court bookings with timestamps and overlap protection
- `public.booking_invitations`: invitation queue state with priority, activation, expiry, and response tracking
- `public.booking_payments`: per-player payment records for a booking
- `public.user_contacts`: normalized contacts / priority list
- `public.user_saved_payment_methods`: normalized saved payment methods

## Key improvements over Firestore

- Booking time uses `timestamptz`, not split string dates and times.
- Court overlap is prevented in the database with an exclusion constraint.
- Invitation queue progression can run server-side instead of relying on fragile client sequencing.
- Centre ownership is provisioned automatically on insert.
- Court availability is generated from operating hours, pricing rules, blocks, and bookings instead of static availability documents.

## RPCs to use from the app

- `public.search_player_directory(search_term, limit_count)`
  - Search the player directory without exposing full private profile rows.
- `public.respond_to_booking_invitation(target_invitation_id, new_status)`
  - Accept, decline, or skip a live invitation atomically.
- `public.get_court_day_availability(target_court_id, target_date, requested_duration_minutes)`
  - Returns computed court slots for one day.

## Background / automation RPC

- `public.expire_stale_booking_work()`
  - Expires pending invitations and cancels stale booking holds.
  - Intended for server-side scheduled execution, not direct client use.
