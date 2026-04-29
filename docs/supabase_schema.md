# Supabase Schema Direction

This project now has a first-pass Supabase schema in:

- `mobile_app/supabase/migrations/20260421093000_initial_oval_schema.sql`

## Why this is different from Firestore

- User data is split into `profiles` (private/sensitive) and `public_profiles` (directory-safe).
- Tennis center managers are stored in a join table instead of `managerIds` arrays.
- Operating hours are normalized into row tables instead of nested maps.
- Bookings use `starts_at` / `ends_at` timestamps instead of string dates and times.
- Booking overlap is prevented at the database level with an exclusion constraint.
- Invitation cascades are modeled as `booking_invitations` rows with queue and pending states.
- Payments are modeled as `booking_payments` rows instead of `creatorPaymentId` / `inviteePaymentId` fields.
- Contacts and saved payment methods are normalized into their own tables.
- Storage buckets and access policies are defined alongside the schema.

## Main tables

- `profiles`
- `public_profiles`
- `tennis_centers`
- `tennis_center_billing`
- `tennis_center_managers`
- `center_operating_hours`
- `courts`
- `court_operating_hours`
- `court_pricing_rules`
- `court_blocks`
- `tennis_center_images`
- `court_images`
- `bookings`
- `booking_invitations`
- `booking_payments`
- `user_contacts`
- `user_saved_payment_methods`

## Immediate follow-up work

- Add data migration scripts from Firebase Auth, Firestore, and Storage.
- Rewrite the Flutter service layer away from Firebase SDKs and onto Supabase.
- Add RPC/functions for slot generation, invitation promotion, and booking confirmation.
