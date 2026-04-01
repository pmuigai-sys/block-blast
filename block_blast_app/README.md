# Aether Block Blast

A cross-platform Flutter puzzle game inspired by Block Blast, built for web, mobile, and desktop with one shared codebase.

## Current State

The app currently includes:

- Adaptive board sizes from `8x8` through `32x32`
- Fixed-orientation custom pieces, including diagonal tip-linked shapes
- Fair offer generation that always includes at least one currently placeable piece
- Row clears, column clears, `2x2` clears, and full-board wipe rewards
- Difficulty-scaled scoring for larger boards
- Audio support for:
  - menu music
  - gameplay music
  - placement / invalid / clear / wipe / game-over SFX
  - spoken praise clips such as `Nice`, `Excellent`, `Amazing`, `Incredible`, and `Aether Clear`
- Native local persistence via SQLite
- Web persistence fallback
- InstantDB integration hooks for cloud snapshot sync and restore
- First-run privacy consent gate before gameplay
- First-run onboarding overlay explaining gameplay and progression
- Built-in telemetry event buffer with copyable diagnostics/session snapshots
- Daily challenge rail with streak tracking and claimable revive-token rewards
- Run summary overlay with combo, clears, and daily progress recap
- Comfort settings:
  - haptics
  - reduced motion
  - high contrast board rendering
- Monetization sandbox hooks:
  - simulated premium unlock
  - simulated rewarded ad flow
  - revive token economy and recovery action

## Project Structure

- `lib/main.dart`
  - Flutter entrypoint
- `lib/src/app.dart`
  - UI, game controller, engine logic, scoring, audio, and InstantDB sync hooks
- `lib/src/session_store_io.dart`
  - Native SQLite-backed session persistence
- `lib/src/session_store_web.dart`
  - Web persistence implementation
- `assets/audio/`
  - Bundled music, SFX, and spoken callout assets

## Run

```powershell
flutter run
```

Useful targets:

```powershell
flutter run -d chrome
flutter run -d windows
flutter run -d android
```

## Cloud Sync

To enable InstantDB sync, pass your app id at runtime:

```powershell
flutter run --dart-define=INSTANTDB_APP_ID=your_app_id
```

Without that define, the game still runs locally and shows sync as not configured.

## Readiness Controls

The side rail now includes commercial-readiness controls:

- Privacy consent status indicator
- App version indicator
- Telemetry event count
- `Copy Session Snapshot` action
- `Copy Diagnostics` action

These copy structured JSON to your clipboard for QA, support, and release triage.

## Release Profile

The app exposes `FLAVOR` and `APP_VERSION` compile-time values:

```powershell
flutter run --dart-define=FLAVOR=staging --dart-define=APP_VERSION=1.0.0-rc1+2
```

These values appear in diagnostics and side-rail status for release confidence checks.

## Verified

The current implementation has been checked with:

```powershell
dart analyze lib\src\app.dart test\widget_test.dart
flutter test test\widget_test.dart --reporter expanded
flutter build web
```

Results:

- analyzer: clean
- test: passing
- web build: successful

## Local Machine Issues

Two platform builds are currently blocked by this machine setup rather than the source code:

- `flutter build windows`
  - blocked because no suitable Visual Studio toolchain is installed
- `flutter build apk --debug`
  - blocked because `JAVA_HOME` points at an invalid JDK path

## Next Setup Fixes

If you want all targets building on this machine, fix:

1. Windows desktop:
   - install the required Visual Studio C++ desktop workload
   - confirm with `flutter doctor`
2. Android:
   - point `JAVA_HOME` to a valid JDK 17+ installation
   - confirm with `flutter doctor`
