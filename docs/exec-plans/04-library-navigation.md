# Exec Plan 04: Library Navigation

## Objective

Build the first library UI for navigating folders, notes, and pages.

## Context

The user mental model is folder-based: for example `Matematica` contains `Lezione 1`, `Lezione 2`, and so on. The MVP should make this structure visible before advanced note editing features arrive.

## Constraints

- Use SwiftUI navigation appropriate for iPad.
- Keep business mutations in view models/use cases, not directly in views.
- Start with local-only data from repositories.
- Do not implement sync, collaboration, search, OCR, or sharing.

## UI Behavior

- App launches into a split-view library.
- Sidebar lists top-level folders.
- Content column lists notes in the selected folder.
- Detail column opens the selected note editor.
- Empty states are allowed only when no folder/note exists.

## Tasks

1. Add a `LibraryViewModel` that loads `NoteLibrarySnapshot`.
2. Add a SwiftUI `NavigationSplitView`.
3. Display folders in the sidebar.
4. Display notes for selected folder.
5. Select the first folder/note from seed data on first launch.
6. Add minimal create-folder and create-note actions.
7. Persist metadata after create actions.
8. Route note selection into the editor from Exec Plan 03.

## Acceptance Criteria

- First launch shows `Matematica` and `Lezione 1`.
- User can select a folder and note.
- User can create a folder.
- User can create a note in the selected folder.
- User can navigate into an editor without placeholder-only UI.

## Tests

- Simulator: launch shows seeded library.
- Simulator: create folder, relaunch, folder remains.
- Simulator: create note, relaunch, note remains.
- Device: navigation works in portrait and landscape.

## Risks

- Nested folders can complicate MVP navigation. Support top-level folders first unless child folders already exist in Domain.
- View model selection state must stay valid after create/delete operations.

## Definition of Done

- Library navigation is usable for the seed workflow.
- Minimal create actions persist.
- Editor route is connected.

