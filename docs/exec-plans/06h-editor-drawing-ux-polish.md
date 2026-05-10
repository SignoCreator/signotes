# Exec Plan 06h: Editor Drawing UX Polish

## Objective

Make the note editor feel like a real drawing/notetaking workspace: multi-page horizontal navigation, a calmer default zoom, page template controls integrated into the toolbar, and a more deliberate top chrome/panel experience.

## Context

The editor already supports one A4 page, PencilKit drawing, zoom/pan, templates, custom tool presets, and autosave. The next milestone should improve the drawing-page UX without changing the persistence format unnecessarily and without touching Apple Pencil Pro-only features.

The existing domain model already supports multiple pages through `NoteDocument.pageIDs`, `NotePage.index`, and per-page `drawingResourceID`. This milestone should use that model and add the missing editor flow around it.

## Constraints

- Keep PencilKit as the drawing engine.
- Keep page backgrounds as metadata, not baked into drawing blobs.
- Keep the architecture as Modular Clean Architecture with MVVM Presentation.
- Do not implement Apple Pencil Pro squeeze/hover/barrel-roll work here.
- Do not introduce a custom renderer here.
- Do not regress current tool preset create/update/delete/autosave behavior.
- Do not let horizontal page navigation fight with active Apple Pencil strokes.
- Keep page, background, canvas, and drawing resource ownership explicit and file-separated.

## UX Behavior

- The editor opens showing the current page slightly more zoomed out than today, so the sheet is visibly a page and not edge-to-edge paper.
- Horizontal navigation moves between pages:
  - swipe/scroll right from the current last page creates a new page.
  - swipe/scroll left/right between existing pages changes the active page.
  - each page keeps its own drawing blob and template metadata.
- Page transition should feel like moving through pages, not like panning inside the same page.
- Zoom/pan remains per active page session state; it must not save as drawing data.
- The page template/background picker moves into the toolbar area as a tool-class control, not as an isolated title-row button.
- Top chrome remains available for back, title, fit/reset zoom, and page position.
- Toolbar handles many presets through horizontal scrolling without clipping tools or popovers.
- Popovers open from the tapped control and must not be clipped by the toolbar or keyboard.

## Implementation Changes

- Domain:
  - Add explicit page queries/mutations to `NoteLibrarySnapshot`: ordered pages for note, append page, and page lookup by ID.
  - New pages use `PageFormat.a4Portrait`, inherit the current page template, and create a unique drawing resource ID.
  - Updating/deleting note data must keep existing recursive delete behavior for all page drawing blobs.
- Presentation ViewModel:
  - Replace single `page` state with ordered pages plus `currentPageID`/index and current page drawing.
  - Flush pending drawing before switching pages or creating a new page.
  - Load drawing data for the selected page only.
  - Expose `goToPreviousPage`, `goToNextPageOrCreate`, and `updateCurrentPageTemplate`.
- Canvas/editor UI:
  - Keep `PencilPageContainerView` responsible for a single active page.
  - Add a page navigation wrapper above it that interprets horizontal page gestures separately from canvas pan/zoom.
  - Use a threshold at page edges so normal panning inside a zoomed page does not accidentally create/switch pages.
  - Reset/fit zoom on page switch unless a better session-only per-page zoom cache is trivial and does not complicate the milestone.
  - Adjust `CanvasViewportConfiguration` so initial fit leaves visible page margin around the A4 sheet.
- Toolbar/chrome:
  - Move template selection from `EditorTopChromeView` title row into the tool palette as a compact background/page-style control.
  - Keep reset zoom in top chrome.
  - Add compact page indicator text, for example `1 / 3`, in top chrome.
  - Preserve existing tool popover behavior: tap selected writing tool opens settings.

## Acceptance Criteria

- User can move page 1 -> page 2 by scrolling/swiping right from the last page.
- User can move back page 2 -> page 1 by scrolling/swiping left.
- Creating a new page persists metadata and a distinct drawing resource ID.
- Writing on page 1 and page 2 persists separately across navigation and app relaunch.
- New page inherits the previous page template.
- Changing template affects only the current page and does not erase handwriting.
- Editor default zoom shows a visible page margin on iPad portrait and landscape.
- Template/background control is integrated into the toolbar, not only the top title row.
- Tool presets still create/update/delete, switch tools, and autosave correctly.
- Toolbar and popovers do not clip in portrait or landscape.

## Tests

- Unit Domain:
  - ordered pages for note sort by `index`.
  - append page adds page ID to note, increments index, and creates a unique drawing resource.
  - appended page inherits requested template.
  - delete note/folder still includes all page drawing resource IDs.
- ViewModel:
  - load selects first page.
  - switching pages flushes pending drawing before loading the next drawing.
  - next from last page creates and selects a new page.
  - template update mutates only the current page.
  - separate page drawings load/save independently.
- Canvas/Geometry:
  - default fit scale is less tight than fit-to-width and keeps visible page margin.
  - zoom clamp still respects configured max zoom.
- Manual iPad:
  - write on page 1, create page 2, write different content, go back and forth.
  - change page 2 to ruled/grid/dotted and verify page 1 is unchanged.
  - pinch zoom, pan, then page-switch only at horizontal edge intent.
  - rotate portrait/landscape and confirm toolbar/page controls remain usable.
  - relaunch app and verify pages, templates, and drawings persist.

## Risks

- Horizontal page navigation can conflict with canvas pan at high zoom.
- Auto-creating pages too eagerly can feel accidental.
- Reloading `PKDrawing` during page switch can drop unsaved strokes if flush ordering is wrong.
- A per-page zoom cache may add complexity; default decision is reset-to-fit on page switch.
- Template control inside the toolbar can overcrowd presets if spacing is not tuned.

## Definition Of Done

- Multi-page editor navigation works on physical iPad.
- Page creation, page switching, templates, drawings, and autosave persist correctly.
- Default zoom gives a better sheet-in-workspace feel.
- Template selection lives in the toolbar experience.
- Existing tool and canvas behavior remains stable.
