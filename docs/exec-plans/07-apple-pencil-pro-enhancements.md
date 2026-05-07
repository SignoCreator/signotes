# Exec Plan 07: Apple Pencil Pro Enhancements

## Objective

Plan optional Apple Pencil Pro enhancements without making them required for the MVP or for standard Apple Pencil users.

## Context

Recent Apple Pencil APIs include squeeze, double tap, hover pose, barrel-roll angle, and haptic feedback. PencilKit also has modern content-version considerations for inks that incorporate barrel-roll data. These features should improve the app on supported hardware while preserving baseline PencilKit behavior everywhere else.

Relevant references:

- Apple Pencil overview: https://developer.apple.com/documentation/ApplePencil
- Apple Pencil updates: https://developer.apple.com/documentation/updates/applepencil
- Handling squeezes: https://developer.apple.com/documentation/ApplePencil/handling-squeezes-from-apple-pencil
- Apple Pencil interactions: https://developer.apple.com/documentation/uikit/apple-pencil-interactions
- Hover and roll APIs: https://developer.apple.com/documentation/uikit/uihovergesturerecognizer/rollangle

## Constraints

- These features are optional and must be availability-guarded.
- App must remain fully usable on non-Pro Apple Pencil.
- Barrel roll should modify marking behavior, not navigation or unrelated UI.
- Do not block MVP shipping on this plan.

## Candidate Features

- Squeeze: show contextual tool controls or quick palette.
- Double tap: respect user action where possible; optionally switch between current tool and eraser.
- Hover preview: show tip/tool preview if user preference allows.
- Barrel roll: influence fountain pen/marker orientation where PencilKit supports it.
- Haptics: use sparingly for snapping or mode changes on supported Pencil Pro hardware.

## Tasks

1. Add a capability layer in Presentation for Pencil interaction events.
2. Implement SwiftUI `onPencilSqueeze` where available, or UIKit `UIPencilInteraction` fallback if the canvas requires UIKit ownership.
3. Add double-tap handling with current Apple API, avoiding deprecated delegate methods.
4. Add hover preview only when supported and when `prefersHoverToolPreview` indicates it is appropriate.
5. Validate whether stored drawings require `PKContentVersion.version3` for modern ink/barrel-roll behavior.
6. Add haptic feedback only for clear, rare state changes.
7. Add device-feature logging for development builds.

## Acceptance Criteria

- Standard Apple Pencil users can write, erase, and navigate normally.
- Unsupported Pro features fail silently or stay hidden.
- Squeeze/double-tap actions are discoverable but not required.
- Barrel-roll behavior is limited to mark-making.
- No compile errors on the iPadOS 18 deployment target.

## Tests

- Non-Pro Pencil device: verify no missing-feature UI blocks writing.
- Pencil Pro device: verify squeeze action triggers intended UI.
- Pencil Pro device: verify hover preview appears only where appropriate.
- Pencil Pro device: verify barrel roll does not trigger navigation.
- Simulator: app compiles with feature guards.

## Risks

- Hardware-specific APIs may be hard to test without Apple Pencil Pro.
- Overusing squeeze/haptics can make the app feel noisy.
- PencilKit may handle some Pro ink behavior internally; avoid duplicating it prematurely.

## Definition of Done

- Feature plan is implemented behind guards.
- Baseline PencilKit MVP remains intact.
- Pro features are additive and tested on supported hardware when available.

