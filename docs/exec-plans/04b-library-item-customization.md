# Exec Plan 04b: Library Item Customization

## Objective

Make library item creation intentional instead of placeholder-only: users can choose names and visual colors for folders and notes when creating them.

## Context

The library grid is now the primary app surface. Folders and notes need user-provided metadata so the app feels like a real note manager instead of a prototype that creates only `Nuova cartella` and `Nuova lezione`.

## Constraints

- Keep customization metadata in Domain, not SwiftUI view state.
- Persist customization through the existing local metadata JSON.
- Do not add iCloud sync, search, drag/drop, OCR, sharing, or deletion in this milestone.
- Keep the app usable with existing persisted metadata that lacks color fields.

## Tasks

1. Add optional visual metadata to Domain:
   - `NotebookFolder.colorHex: String?`
   - `NoteDocument.colorHex: String?`
2. Update creation mutations to accept `name/title` and `colorHex`.
3. Add a SwiftUI creation sheet for folders and notes:
   - text field for name/title
   - small fixed color palette
   - disabled confirm while trimmed text is empty
4. Use chosen colors in library grid tiles.
5. Persist created item names/colors through `NotesRepository`.
6. Add tests for custom folder/note metadata persistence through view-model mutations.

## Acceptance Criteria

- Creating a root folder asks for a name and color.
- Creating a child folder asks for a name and color.
- Creating a note asks for a title and color.
- Created folder/note appears immediately in the grid with the chosen text and color.
- Relaunch/load preserves names and colors.
- Existing libraries without color metadata still load and render with defaults.

## Tests

- Unit: `addFolder` stores trimmed name and color.
- Unit: `addNote` stores trimmed title and color.
- ViewModel: custom root folder creation persists selected name/color.
- ViewModel: custom note creation persists selected title/color in current folder.
- Device manual: create folder/note with non-default colors, relaunch, verify they remain.

## Risks

- Too many color choices can slow MVP decisions. Use a small fixed palette for now.
- Rename/edit metadata can be added next; this plan only covers creation-time customization.

## Definition of Done

- Creation no longer relies on placeholder-only names.
- Library grid reflects custom colors.
- Metadata persists and tests cover the behavior.
