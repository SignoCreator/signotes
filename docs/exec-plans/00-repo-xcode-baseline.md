# Exec Plan 00: Repo and Xcode Baseline

## Objective

Normalize the repository after opening the skeleton project in Xcode, then verify that the app can build, sign, install, and run on a physical iPad.

## Context

The repository is a native iPadOS SwiftUI app skeleton. Xcode may generate project workspace metadata and signing changes when the project is opened locally. Keep durable project metadata, but do not track developer-specific UI state.

Relevant references:

- Apple Xcode device run flow: https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device
- Apple Pencil overview: https://developer.apple.com/documentation/ApplePencil

## Constraints

- Do not remove existing user/Xcode changes without reviewing them.
- Keep `Signotes.xcodeproj/project.xcworkspace/contents.xcworkspacedata` if Xcode created it.
- Do not track `xcuserdata` or `*.xcuserstate`.
- Keep deployment target at iPadOS `18.0` unless Xcode/device compatibility requires a change.
- Keep the target iPad-only (`TARGETED_DEVICE_FAMILY = 2`).

## App Bundle Exclusions

Repository documentation is for developers and must not be copied into the installed iPad app.

Do not add these files or folders to the app target's `Copy Bundle Resources` phase:

- `README.md`
- `docs/**`
- `docs/exec-plans/**`
- architecture or planning Markdown files
- local notes, screenshots, scratch files, or test fixtures not required at runtime
- `.gitignore`, Git metadata, Xcode user state, or other development-only files

Only include runtime assets that the app needs while installed, such as `Assets.xcassets`, localized app resources, bundled templates explicitly required by the product, or fixture data deliberately shipped for a debug build.

## Tasks

1. Inspect `git status --short` and `git diff`.
2. Confirm `.gitignore` includes `.DS_Store`, `xcuserdata/`, `*.xcuserstate`, build outputs, and DerivedData.
3. Review any `Signotes.xcodeproj/project.pbxproj` changes from Xcode.
4. Preserve signing team changes only if they are required for local device install.
5. Add `Signotes.xcodeproj/project.xcworkspace/contents.xcworkspacedata` if present.
6. Verify that `Signotes.xcodeproj/project.xcworkspace/xcuserdata/**` is ignored.
7. Inspect the app target's `Copy Bundle Resources` build phase.
8. Remove any developer-only docs from app resources if Xcode added them.
9. Open the project in Xcode.
10. Select a simulator and build once.
11. Select a physical iPad and run once.
12. Commit only baseline project files and docs, not personal Xcode state.

## Acceptance Criteria

- `git status --short` shows no accidental `xcuserdata` or `.xcuserstate` files.
- The app opens in Xcode without project repair prompts.
- The app builds for an iPad simulator.
- The app installs and launches on a physical iPad.
- Signing is configured through Xcode automatic signing.
- The installed app bundle does not contain `README.md`, `docs/**`, or exec-plan Markdown files.

## Manual Tests

- Simulator: build and run `Signotes` on an iPad simulator.
- Device: connect iPad, trust the Mac, select the iPad in Xcode, run the app.
- Git: run `git status --ignored --short` and confirm ignored Xcode user state is not staged.
- Bundle resources: inspect the target membership/build phase and confirm developer docs are not bundled.

## Risks

- Xcode may rewrite `project.pbxproj`; review the diff before staging.
- A local development team ID may be user-specific. Keep it only if the repo owner wants local signing committed.
- Device preparation can take several minutes on first run.

## Definition of Done

- Baseline repo state is clean.
- Xcode can build the skeleton.
- The app launches on iPad.
- Only durable project metadata is tracked.
