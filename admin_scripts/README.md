# Legacy Admin Scripts

These scripts are legacy Firebase-era maintenance utilities.
They are not part of the active Supabase runtime and should not be treated as the production backend.

## Current Status

- The mobile app now uses Supabase for auth and data.
- These scripts remain only as historical utilities.
- Do not use them as the basis for current operational workflows without a deliberate migration review.

## If You Need Admin Automation Now

Prefer one of these paths instead:
- Supabase SQL migrations and RPCs
- Supabase Edge Functions
- audited one-off scripts that target the current Supabase schema

## Secret Handling

If any legacy script still needs local credentials, keep them out of git and use local-only files such as ignored templates.
