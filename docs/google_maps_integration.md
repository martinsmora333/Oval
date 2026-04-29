# Google Maps Integration

## Current Source of Truth

Google Maps and Places configuration should come from local environment values, not hardcoded plist entries and not a bundled Flutter asset.

Local development flow:
1. Create `.env` from `.env.example`
2. Add `GOOGLE_MAPS_API_KEY`
3. Optionally add a dedicated `GOOGLE_PLACES_API_KEY`
4. Run the app with `./scripts/flutter_with_env.sh run`

## Runtime Configuration

Flutter reads client-safe config from Dart defines.
The local wrapper script injects:
- `GOOGLE_MAPS_API_KEY`
- `GOOGLE_PLACES_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Native Configuration

### Android

`android/app/build.gradle` reads `.env` and provides the Google Maps API key through manifest placeholders.

### iOS

`ios/Podfile` reads `.env` and generates `ios/Runner/GoogleMaps-Info.plist`.
`ios/Runner/AppDelegate.swift` initializes Google Maps from that generated plist.

## What Not To Do

- Do not hardcode API keys in `Info.plist`
- Do not commit `.env`
- Do not ship placeholder keys in widgets or screens

## Active Map Components

- `lib/config/maps_config.dart`
- `lib/widgets/map_with_search.dart`
- `lib/widgets/map_picker.dart`
- `lib/widgets/location_search_bar.dart`
- `lib/utils/map_cluster_manager.dart`
- `lib/utils/map_utils.dart`

## Release Notes

Before production:
- restrict the Maps and Places keys by platform and bundle/package identifiers
- review whether background location permissions are actually needed
- validate store privacy strings against the final location behavior
