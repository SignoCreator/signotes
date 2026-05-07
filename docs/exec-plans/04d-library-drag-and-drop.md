# Exec Plan 04d: Library Drag and Drop

## Objective

Add drag and drop item organization to the library grid so users can move notes and folders across the local hierarchy without breaking recursive folder invariants.

## Context

The library now has recursive folders, note/folder create/update/delete, and a grid UI. The next filesystem-like behavior is moving items by dragging them onto folders or into the root area.

## Constraints

- Keep drag/drop as a Presentation interaction that dispatches explicit ViewModel intents.
- Keep all tree mutation rules in `NoteLibrarySnapshot`.
- Prevent invalid moves:
  - a folder cannot be moved into itself
  - a folder cannot be moved into one of its descendants
  - a note can only have one parent folder
  - a folder can only have one parent folder or be root
- Do not implement multi-select, external file import/export, duplicate, undo, or trash in this milestone.
- Drag and drop must remain additive; context menus and toolbar creation keep working.

## Tasks

1. Add Domain mutations:
   - move note to folder
   - move folder to folder
   - move folder to root
   - reject cycles and invalid self/descendant drops
2. Add ViewModel commands for move operations.
3. Add lightweight drag payload modeling for local library items.
4. Add drop targets:
   - folder tile accepts notes and valid folders
   - root/library background accepts folders moved to root
5. Add visual drop feedback using system-appropriate highlight states.
6. Persist the updated library after each successful move.
7. Add tests for valid moves and invalid cycle prevention.

## Acceptance Criteria

- User can drag a note onto a folder and the note moves there.
- User can drag a folder onto another folder and the folder becomes a child.
- User can move a nested folder back to root.
- Dropping a folder onto itself or a descendant is rejected.
- UI updates immediately after a successful drop and persists after relaunch.
- Existing create/update/delete/navigation behavior remains unchanged.

## Tests

- Unit: moving a note removes it from the old folder and adds it to the new folder.
- Unit: moving a folder removes it from the old parent and adds it to the new parent.
- Unit: moving a folder to root removes parent references.
- Unit: moving a folder into itself throws.
- Unit: moving a folder into a descendant throws.
- ViewModel: successful note move persists.
- ViewModel: successful folder move persists and updates visible grid.
- Device: drag note to folder, drag folder to folder, drag folder to root, relaunch, verify hierarchy.

## Risks

- iPad drag and drop can become hard to discover if there is no visible feedback. Keep drop highlights clear but restrained.
- Recursive folder moves can corrupt navigation if Domain invariants are bypassed. All move logic must go through `NoteLibrarySnapshot`.
- A drag gesture must not conflict with context menu long press more than necessary.

## Definition of Done

- Drag/drop organization is implemented behind explicit ViewModel methods.
- Invalid tree moves are covered by tests.
- Simulator tests pass.
- Physical iPad smoke test confirms drag/drop behavior with touch.
