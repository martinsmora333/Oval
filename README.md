# Oval Mobile App

Flutter mobile app for Oval, a tennis marketplace where players discover courts, book sessions, invite opponents, and manage match logistics.

## Repo Scope

This repository root is `/Users/martin/CascadeProjects/tennis_match_platform/mobile_app`.
It is the authoritative app codebase.

The parent workspace currently also contains historical or out-of-scope folders such as:
- `../firebase/`
- `../web_dashboard/`
- `../flutter/`

Those folders are not part of the active mobile app runtime and should not be treated as the source of truth for shipping the app.

## Current Stack

- Flutter
- Supabase Auth / Postgres / Storage
- Google Maps / Places
- Stripe client SDK, with server-side payment work still required before production

## Local Setup

1. Copy the config template:
```bash
cp .env.example .env
```
2. Fill in the local values in `.env`.
3. Install Dart and Flutter packages:
```bash
flutter pub get
```
4. Run the app with local config injected as Dart defines:
```bash
./scripts/flutter_with_env.sh run
```

## Build Commands

Debug Android build:
```bash
./scripts/flutter_with_env.sh build apk --debug
```

Run tests:
```bash
flutter test
```

Analyze app code:
```bash
dart analyze lib test
```

## Configuration Strategy

Client-safe values are injected at build time with `--dart-define`.
For local development, use `./scripts/flutter_with_env.sh`, which loads `.env` and forwards the required values to Flutter.

Native platform builds still read the same local `.env` file for platform-specific Google Maps setup:
- Android: `android/app/build.gradle`
- iOS: `ios/Podfile`

Do not commit `.env` or generated native config files.

## Important Documents

- `docs/development_setup.md`
- `docs/google_maps_integration.md`
- `docs/secrets_policy.md`
- `docs/supabase_schema.md`

## Current Product Status

This repo contains the mobile app only.
The backend schema has been moved to Supabase, but production readiness still depends on completing:
- server-side booking creation workflow
- server-side invitation lifecycle automation
- real Stripe payment orchestration and webhooks
- release signing, observability, and CI
