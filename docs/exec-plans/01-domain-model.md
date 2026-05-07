# Exec Plan 01: Domain Model

## Objective

Define the core Signotes domain entities without importing SwiftUI, UIKit, PencilKit, or filesystem APIs.

## Context

The app follows Modular Clean Architecture with MVVM Presentation. The Domain layer owns app concepts, not platform rendering details. PencilKit-specific objects must stay out of Domain so that a future custom renderer can reuse the same note/page model.

## Constraints

- Domain files must not import `SwiftUI`, `UIKit`, `PencilKit`, or `Foundation` APIs beyond simple value/data needs.
- Prefer value types.
- Make metadata models `Codable`, `Equatable`, and `Identifiable` where useful.
- Use stable `UUID` identifiers for folders, notes, pages, and presets.
- Do not encode `PKDrawing` in Domain.

## Types to Add

- `NotebookFolder`
  - `id: UUID`
  - `name: String`
  - `noteIDs: [UUID]`
  - `childFolderIDs: [UUID]`

- `NoteDocument`
  - `id: UUID`
  - `folderID: UUID`
  - `title: String`
  - `pageIDs: [UUID]`
  - `createdAt: Date`
  - `updatedAt: Date`

- `NotePage`
  - `id: UUID`
  - `noteID: UUID`
  - `index: Int`
  - `format: PageFormat`
  - `template: PageTemplate`
  - `drawingResourceID: String`

- `PageFormat`
  - case `a4Portrait`
  - expose width/height points through domain-neutral numeric values.

- `PageTemplate`
  - cases `blank`, `ruled`, `grid`, `dotted`.

- `DrawingToolPreset`
  - `id: UUID`
  - `name: String`
  - `kind: DrawingToolKind`
  - `colorHex: String`
  - `width: Double`

- `DrawingToolKind`
  - cases `fountainPen`, `pen`, `pencil`, `marker`, `eraser`, `lasso`.

## Tasks

1. Add model files under `Signotes/Domain/Models`.
2. Add a `NoteLibrarySnapshot` aggregate for persisted metadata.
3. Add a static `seed` snapshot with `Matematica` and `Lezione 1`.
4. Keep all ordering explicit through arrays of IDs.
5. Add domain validation helpers only if needed for indexing and page ordering.

## Acceptance Criteria

- Domain models compile independently of Presentation/Data imports.
- Metadata can be encoded/decoded as JSON.
- A seed library can be created deterministically enough for first launch.
- Page format exposes the A4 portrait aspect ratio without UI dependencies.

## Tests

- Unit test JSON encode/decode round trip for `NoteLibrarySnapshot`.
- Unit test A4 portrait aspect ratio equals `210 / 297`.
- Unit test seed contains one folder named `Matematica`, one note named `Lezione 1`, and one page.

## Risks

- Embedding PencilKit types now would make the future renderer harder.
- Tree structures can become hard to mutate if nested directly; use IDs for MVP simplicity.

## Definition of Done

- Domain model files are present and compile.
- No UI or PencilKit imports exist in Domain.
- Seed metadata exists and is covered by tests.

