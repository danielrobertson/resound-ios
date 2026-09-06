---
name: run
description: Build resound-ios and launch it in the iOS Simulator. Use whenever asked to run, build, or verify the app, or after making code changes that should be checked in the Simulator.
---

# Running resound-ios

This machine's `xcode-select -p` points at CommandLineTools, not Xcode, so bare `xcodebuild` fails with
"requires Xcode, but active developer directory is a command line tools instance". Prefix every
`xcodebuild`/`xcrun` call with:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Don't chase inline SourceKit squiggles in the editor (e.g. "cannot find type in scope") — SourceKit is
unreliable in this setup and misreports valid, pre-existing code. Trust the `xcodebuild` result instead.

## 1. Build

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project resound-ios.xcodeproj -scheme resound-ios \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

Run from the repo root. Fix any build errors before continuing.

## 2. Boot the simulator (if needed)

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl list devices available
```

Look for "iPhone 17" (or another available iOS device) and its UDID. If it isn't `(Booted)`:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl boot <UDID>
open -a Simulator
```

## 3. Find the built .app and install it

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project resound-ios.xcodeproj \
  -scheme resound-ios -destination 'platform=iOS Simulator,name=iPhone 17' \
  -showBuildSettings build | grep -m1 " BUILT_PRODUCTS_DIR "
```

Then:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl install <UDID> "<BUILT_PRODUCTS_DIR>/resound-ios.app"
```

## 4. Launch

Bundle id is `com.danielrobertson.resound-ios`:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl launch <UDID> com.danielrobertson.resound-ios
```

## 5. Verify visually

Take a screenshot rather than assuming the launch worked:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl io <UDID> screenshot <scratchpad>/screenshot.png
```

Then read the PNG back to look at it.

## Tests

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project resound-ios.xcodeproj -scheme resound-ios \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```
