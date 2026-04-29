# Oval Workspace

This repository is the top-level workspace for Oval.

## Active Product

The active shipping codebase is the Flutter mobile app in `mobile_app/`.
That app currently uses:
- Flutter
- Supabase Auth / Postgres / Storage
- Google Maps / Places
- Stripe client SDK, with server-side payment work still required before production

## Workspace Layout

- `mobile_app/`: authoritative application repo content
- `docs/`: legacy workspace notes
- `firebase/`: historical Firebase-era material, no longer the active backend
- `web_dashboard/`: currently unused / not an active product surface
- `flutter/`: local Flutter SDK checkout for development convenience, not product source

## Repo Rules

- Treat `mobile_app/` as the source of truth for app code.
- Do not commit local secrets.
- Do not treat `firebase/` as the current runtime architecture.
- Do not treat `web_dashboard/` as a live deliverable until it is intentionally rebuilt.

## Current Status

The workspace has been migrated toward Supabase, but production readiness still depends on:
- trusted backend booking creation
- trusted invitation lifecycle automation
- real Stripe payment orchestration and webhooks
- release hardening, CI, and observability
