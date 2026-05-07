# Exec Plan 04c: Library Item Management & Refactor

## Objective

Refactor the library UI into maintainable presentation components and add full metadata management for folders and notes: update name/color and delete items.

## Context

The library grid is now the primary navigation surface. Creation customization exists, but `LibraryView` has accumulated too many responsibilities and there is no way to edit or delete existing folders and notes.

## Constraints

- Keep Domain mutations in `NoteLibrarySnapshot`, not in SwiftUI views.
- Keep drawing blob deletion behind `DrawingRepository`.
- Delete folders recursively after explicit confirmation.
- Do not add drag/drop, duplicate, search, undo, trash/recycle bin, or inline rename.
- Existing libraries with optional color metadata must keep loading.

## Tasks

1. Split library Presentation into focused components:
   - container view
   - grid/tile rendering
   - create/update sheet
   - shared visual helpers
2. Add Domain helpers:
   - update folder name/color
   - update note title/color
   - delete note and return drawing resource IDs
   - delete folder tree and return drawing resource IDs
3. Extend `DrawingRepository` with drawing deletion.
4. Update `LibraryViewModel` with create, update, and delete commands.
5. Add context menus for folder/note tiles:
   - `Modifica`
   - `Elimina`
6. Add confirmation dialogs for destructive actions.
7. Preserve navigation after deletion:
   - deleting current folder returns to parent or root
   - deleting a note stays in the current folder

## Acceptance Criteria

- `LibraryView` is a composition/container, not the owner of all UI detail.
- Users can update folder name/color.
- Users can update note title/color.
- Users can delete notes.
- Users can recursively delete folders after confirmation.
- Drawing blobs for deleted pages are deleted when present and ignored when already missing.
- Tests cover update/delete behavior.

## Tests

- Unit: folder update stores trimmed name and color.
- Unit: note update stores trimmed title and color.
- Unit: note deletion removes note, pages, and folder reference.
- Unit: folder tree deletion removes nested folders, notes, pages, and parent reference.
- Unit: file-system drawing delete removes an existing blob and ignores a missing blob.
- ViewModel: folder update persists.
- ViewModel: note update persists.
- ViewModel: note delete updates the visible note list.
- ViewModel: deleting the current folder navigates to parent or root.
- Device: create, edit, delete note, delete folder with content, relaunch, verify persistence.

## Risks

- Recursive delete is destructive. Keep confirmation copy explicit.
- Context menus on iPad must remain discoverable enough for MVP; toolbar create remains visible.

## Definition of Done

- Library item management is implemented and pushed.
- Tests pass on simulator.
- Build, install, and launch pass on physical iPad.
