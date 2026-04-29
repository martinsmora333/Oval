# Development Setup

## Repo Root

Use `/Users/martin/CascadeProjects/tennis_match_platform/mobile_app` as the repo root for app work.
The parent workspace contains historical folders that are not the active shipping target.

## Local Configuration

1. Copy the template:
```bash
cp .env.example .env
```
2. Fill in:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_MAPS_API_KEY`
- `GOOGLE_PLACES_API_KEY` if you want a dedicated Places key

## Running the App

Use the wrapper script so Flutter receives the same values the native builds use:
```bash
./scripts/flutter_with_env.sh run
```

Useful variants:
```bash
./scripts/flutter_with_env.sh build apk --debug
./scripts/flutter_with_env.sh run -d ios
./scripts/flutter_with_env.sh run -d android
```

## Analysis and Tests

```bash
dart analyze lib test
flutter test
```

## Native Notes

- Android reads Google Maps config from `.env` in `android/app/build.gradle`.
- iOS generates `ios/Runner/GoogleMaps-Info.plist` from `.env` during `pod install` via `ios/Podfile`.
- `ios/Runner/GoogleMaps-Info.plist` is generated local state and is intentionally ignored by git.

## Production Direction

This setup is for local and staging development.
Longer-term production configuration should move to environment-specific CI/CD injection and store-managed secrets, not ad-hoc local files.
