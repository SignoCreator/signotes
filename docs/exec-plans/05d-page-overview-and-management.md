# Exec Plan 05d: Page Overview And Management

## Objective

Add an editor page overview panel that lets users inspect page previews, jump to a page, manage page insertion/deletion/duplication, reorder pages with drag and drop, and add a page from a final `+` card.

## Context

The editor already supports multi-page notes, adjacent page previews, page templates, carousel-style page turns, and preview image caching. The next page-level workflow is a GoodNotes/OneNote-style page browser so users can manage longer notes without swiping one page at a time.

## UX Direction

- Add a page-overview button in the editor toolbar, preferably near page/template controls rather than inside the writing-tool cluster.
- Present the overview as a left-side panel on regular iPad width.
- Use a compact full-height sheet or panel on narrow width if split layout becomes cramped.
- Keep the canvas visible on the right when space allows.
- Show pages in a two-column grid of page preview cards.
- Highlight the current page with a clear accent border.
- Put a final dashed `+` card after the last page to append a new page.

## Constraints

- Keep page management logic in ViewModel and Domain-style snapshot mutations, not inside SwiftUI views.
- Keep preview rendering based on the existing `EditorPagePreview` / `EditorPagePreviewImageCache` path.
- Apply DRY rigorously: if existing editor, preview, persistence, or domain logic already covers part of this behavior, reuse or extract shared helpers instead of duplicating it.
- Preserve clear responsibility boundaries:
  - Domain owns page ordering and metadata invariants.
  - Data repositories own drawing blob persistence.
  - ViewModel owns editor intents, selection, autosave flushing, and error surfacing.
  - SwiftUI views own layout, menus, drag/drop gestures, and visual state only.
- Do not render every page with live `PKCanvasView`; thumbnails must be raster previews.
- Load thumbnails lazily for visible or near-visible pages where practical.
- Preserve existing touch behavior:
  - Apple Pencil writes only on the canvas.
  - finger drag in the overview reorders pages.
  - page carousel gestures keep working when the overview is closed.
- Do not implement bookmarks, search, outline, multi-select, export, trash, undo, or page grouping in this milestone.

## Tasks

1. Add Domain/ViewModel page mutations:
   - insert page before page ID
   - insert page after page ID
   - duplicate page after source page ID
   - delete page by ID
   - move page from one index to another
2. Ensure mutations preserve sequential page indexes and persist metadata.
3. Extend drawing persistence behavior:
   - duplicated page gets a new `drawingResourceID`
   - duplicate copies the source drawing blob if present
   - delete removes the page drawing blob; missing blobs do not block metadata deletion
   - deleting the current page selects the nearest remaining page
   - never allow a note to have zero pages; deleting the last page should create/select a replacement blank page or reject deletion with disabled UI
4. Add `EditorPageOverviewPanel` in Presentation:
   - title `Pagine`
   - close button
   - scrollable two-column preview grid
   - current-page selection state
   - final dashed `+` append card
5. Add `EditorPageOverviewTile`:
   - thumbnail preview
   - page number
   - small down-chevron/menu affordance under or beside the number
   - selected border for the active page
6. Add tile interactions:
   - tap thumbnail/card: navigate to page
   - tap chevron: open menu with `Aggiungi pagina prima`, `Aggiungi pagina dopo`, `Duplica`, `Elimina`
   - long press/drag: reorder pages before or after other pages
7. Add delete confirmation for destructive delete.
8. Keep insertion/duplication template defaults:
   - insert before/after uses the current or neighboring page template
   - duplicate keeps source template and drawing
   - final `+` appends using current page template
9. Add loading/error states:
   - thumbnail unavailable uses template-only preview
   - corrupt drawing thumbnail does not crash the panel
   - persistence errors surface through existing editor error UI

## Acceptance Criteria

- User can open and close the page overview from the editor toolbar.
- User can tap a page preview and the editor navigates to that page.
- Current page is visually highlighted in the overview.
- User can add a page before or after any page from the tile menu.
- User can duplicate a page, including its handwriting and template.
- User can delete a page with confirmation, and the editor lands on a valid remaining page.
- User cannot accidentally delete the only usable page without replacement behavior.
- User can long-press and drag a page tile to reorder pages.
- Page indexes and page numbers remain correct after insert, duplicate, delete, and reorder.
- The final `+` card appends a page at the end.
- Existing carousel page turning, canvas writing, toolbar tools, templates, autosave, and zoom remain working.

## Tests

- Unit Domain/ViewModel:
  - insert before reindexes pages and selects/persists correctly
  - insert after reindexes pages and selects/persists correctly
  - duplicate creates a new page ID and drawing resource ID
  - duplicate copies drawing data when present
  - delete removes metadata and drawing data
  - delete current page selects nearest valid page
  - delete last page follows the chosen replacement/disabled behavior
  - move page reorders indexes without losing drawings
- Presentation/ViewModel:
  - tapping a page calls explicit navigation by page ID
  - final `+` appends a page
  - menu actions dispatch the correct ViewModel commands
  - drag/drop reorder persists and updates visible order
- Manual iPad:
  - open overview in landscape and portrait
  - navigate from page list
  - insert before/after
  - duplicate handwriting page
  - delete current/non-current page
  - reorder via long press drag
  - close panel and verify carousel still works
  - relaunch and verify page order/content persists

## Risks

- Thumbnail generation can become expensive on long notes. Reuse the existing preview cache and avoid live canvas thumbnails.
- Drag/drop can conflict with menu long press. Prefer a clear drag handle or tile drag gesture that does not block the chevron menu.
- Deleting/reordering while autosave is pending can lose strokes. Flush pending drawing before page-management mutations.
- Duplicating large drawings can take noticeable time. Keep the UI responsive and surface errors.

## Suggestions

- Add a small page count indicator in the panel header, e.g. `23 pagine`.
- Consider a compact segmented control later for `Tutte`, `Preferite`, `Modificate`, but do not implement it in this milestone.
- Consider a drag handle icon on each tile if long-press drag proves undiscoverable.
- Consider haptic feedback on successful reorder/drop where available.

## Definition Of Done

- Page overview panel is implemented with preview grid, page navigation, page actions, reorder, and final append card.
- Page mutations are covered by tests and persist correctly.
- Rendering remains limited to current canvas plus cached thumbnails.
- Physical iPad smoke test passes in portrait and landscape.
