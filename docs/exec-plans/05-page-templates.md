# Exec Plan 05: Page Templates

## Objective

Add page backgrounds for blank, ruled, grid, and dotted paper without baking them into handwriting data.

## Context

Users expect A4 pages that look like real paper. Templates are metadata attached to a page. Handwriting remains separate so changing paper style does not erase or mutate strokes.

## Constraints

- Template is stored on `NotePage`.
- Drawing data remains independent from template rendering.
- Template rendering must work behind the PencilKit canvas.
- Keep visual output clean at common iPad sizes and zoom levels.

## Template Behavior

- `blank`: white page only.
- `ruled`: horizontal blue/gray guide lines.
- `grid`: square grid suitable for math notes.
- `dotted`: evenly spaced dots.

## Tasks

1. Add a `PageBackgroundView` in `Presentation/Canvas`.
2. Render the current page template behind `PKCanvasView`.
3. Add a template picker in the editor toolbar or page settings.
4. Save template changes through metadata persistence.
5. Ensure switching templates does not touch drawing blobs.
6. Prepare export/render code path to composite background + drawing later.

## Acceptance Criteria

- All four templates render.
- Changing template does not erase handwriting.
- Template choice persists after relaunch.
- Grid/dot spacing remains stable when page resizes.
- Canvas remains transparent over the background.

## Tests

- Simulator: switch each template and relaunch.
- Device: write on grid, switch to ruled, confirm strokes remain.
- Visual check: no template lines appear above handwriting.
- Visual check: templates do not shift layout when selected.

## Risks

- Rendering templates with too much detail can hurt performance.
- Template color/spacing may need UX tuning after real note-taking tests.

## Definition of Done

- Template metadata and rendering are implemented.
- Strokes and paper backgrounds are separate.
- The page remains usable for math notes.

