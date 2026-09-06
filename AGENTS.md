# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project

Native SwiftUI port of the web app in the sibling repo `/Users/daniel/code/resound` (design source of truth: `src/styles.css`, studio UI in `src/routes/studio.tsx`).

- Xcode project: `resound-ios.xcodeproj`, scheme `resound-ios`, bundle id `com.danielrobertson.resound-ios`.
- Storage is local-first: SwiftData + files in Application Support/Recordings, with `Recording.syncState` tracking sync to Firebase (`resound-2618a` project — Auth, Firestore, Storage, FirebaseAI, AppCheck via SPM). `FirebaseBootstrap.configure()` no-ops if `GoogleService-Info.plist` is missing. `GoogleService-Info.plist` is deliberately tracked in git — it ships inside the app bundle and isn't a secret.
- Layout: `resound-ios/{Models,Store,Services,Audio,DesignSystem,Views,Resources}`; tests in `resound-iosTests/`.

## Build & run

Use the `run` skill (or see `.Codex/skills/run/SKILL.md`) to build and launch the app in the Simulator. Key gotcha: `xcode-select -p` on this machine points at CommandLineTools, not Xcode, so bare `xcodebuild` fails — prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

Trust `xcodebuild`'s result over inline SourceKit diagnostics in the editor — SourceKit is unreliable in this setup and reports bogus "cannot find type in scope" errors for valid, pre-existing code.

## Verification

- Don't write tests during active development (features, fixes, refactors) unless explicitly asked — treat the project's normal build as the bar for done.
- After making changes, rebuild and launch the app in the Simulator (see Build & run above) to confirm it works — don't just rely on a clean compile.
