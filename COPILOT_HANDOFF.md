# Copilot Handoff: Aether Block Blast

Date: 2026-03-30
Repo root: `F:\block-blast`
App root: `F:\block-blast\block_blast_app`

## Current Status
- Flutter app baseline is implemented and functional in `block_blast_app`.
- Verified previously:
  - `dart analyze lib\src\app.dart test\widget_test.dart` passed
  - `flutter test test\widget_test.dart --reporter expanded` passed
  - `flutter build web` succeeded
- Known machine blockers (environment-only):
  - `flutter build windows` fails due to missing Visual Studio desktop C++ toolchain
  - `flutter build apk --debug` fails due to invalid `JAVA_HOME`

## What Exists Now
- Cross-platform Flutter game for web, mobile, desktop.
- Board sizes `8x8` to `32x32`, difficulty-scaled scoring.
- Fixed-orientation piece library including diagonal tip-linked shapes.
- Offer generator guarantees at least one valid placement and favors future-fit.
- Clears: rows, columns, `2x2`, full-board wipe.
- Audio: menu/gameplay music, SFX, and voice callouts.
- Persistence:
  - Native SQLite store: `block_blast_app/lib/src/session_store_io.dart`
  - Web store: `block_blast_app/lib/src/session_store_web.dart`
- InstantDB hook for snapshot sync/restore when `INSTANTDB_APP_ID` is provided.
- Challenges are wired to run state (cascade and wipe).

Key files:
- `block_blast_app/lib/src/app.dart`
- `block_blast_app/lib/src/session_store.dart`
- `block_blast_app/lib/src/session_store_io.dart`
- `block_blast_app/lib/src/session_store_web.dart`
- `block_blast_app/README.md`

## Git Status
- Branch: `main`
- No remote configured yet (intended remote: `thairux/block-blast`)
- Working tree currently uncommitted at the time of handoff.
- Repo-level `.gitignore` has been added at `F:\block-blast\.gitignore`.

## Required Initial Publish (atomic commits)
1. Commit repo metadata:
   - `.gitignore`
   - `GENERAL_AUTOPILOT_INSTRUCTIONS.md`
   - Commit message: `chore(repo): bootstrap repository metadata`
2. Commit app baseline:
   - `block_blast_app/`
   - Commit message: `feat(app): add Aether Block Blast Flutter baseline`
3. Create remote and push:
   - `gh repo create thairux/block-blast --source . --remote origin --private`
   - `git push -u origin main`

## Commercial Viability Gaps (priority order)
1. First-session onboarding and tutorial loop.
2. Real challenge system: daily/weekly rotation, claimable rewards, streaks.
3. Identity + competitive surfaces: sign-in flow, profile, leaderboards.
4. Meta progression: achievements, unlocks, player level, mode taxonomy.
5. Settings/compliance: haptics, accessibility, language, privacy, data export/reset.
6. Monetization architecture: rewarded continue, cosmetics, entitlements, restore.
7. Release hardening: CI, telemetry/crash hooks, legal pages, store assets.
8. Polish: stronger placement feedback, combos, end-of-run ceremony.

## Suggested Next Slice (after publish)
Implement onboarding + a guided first-run tutorial and better end-of-run summary.
This is the smallest high-impact retention improvement.

## Notes
- `rg` can fail in this environment with access-denied; use PowerShell `Get-ChildItem` or `Select-String` when needed.
- `gh auth status` is already logged in as `Thairux` with `repo` and `workflow` scopes.
