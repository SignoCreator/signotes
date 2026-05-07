# Signotes

Open source iPad note-taking app focused on Apple Pencil handwriting, A4 pages, paper templates, and a fountain pen writing experience.

## Architecture

Signotes uses a **modular Clean Architecture with MVVM for SwiftUI presentation**:

- `Domain`: models, repository protocols, and use cases.
- `Data`: concrete persistence implementations.
- `Presentation`: SwiftUI screens, view models, and PencilKit bridge.
- `App`: app composition and dependency wiring.

The project currently contains only the architectural skeleton and a minimal SwiftUI app entry point. Implementation starts from the MVP plan in `docs/MVP.md`.

Execution plans for the MVP milestones live in `docs/exec-plans/`.

## Development

Open `Signotes.xcodeproj` in Xcode, select an iPad simulator or physical iPad, choose your signing team, then run the app.

The first implementation target is native iPadOS with SwiftUI + PencilKit.
