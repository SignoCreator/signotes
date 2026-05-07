# Exec Plan 03: PencilKit A4 Canvas

## Objective

Build the first usable note editor: one A4 portrait page with a PencilKit canvas and native fountain pen input.

## Context

PencilKit provides low-latency Apple Pencil capture, rendered strokes, eraser, lasso, and serializable `PKDrawing` data. The MVP should use PencilKit directly instead of building a custom renderer.

Relevant references:

- PencilKit overview: https://developer.apple.com/documentation/pencilkit
- Drawing with PencilKit: https://developer.apple.com/documentation/PencilKit/drawing-with-pencilkit
- `PKCanvasView`: https://developer.apple.com/documentation/pencilkit/pkcanvasview
- `PKInkingTool`: https://developer.apple.com/documentation/pencilkit/pkinkingtool

## Constraints

- Use `PKCanvasView` through a SwiftUI `UIViewRepresentable`.
- Default tool is native fountain pen: `PKInkingTool(.fountainPen, color: .black, width: ...)`.
- Keep custom renderer out of MVP.
- Drawing must be clipped/framed to the visual A4 page.
- Physical iPad testing is required for Apple Pencil behavior.

## UI Behavior

- Editor opens the selected note and current page.
- Page appears as a white A4 portrait surface centered in a scrollable workspace.
- Canvas is transparent over the page background.
- Finger input policy should prefer Pencil for drawing; finger remains available for scrolling where practical.
- Current drawing loads when the page appears and saves through the persistence layer.

## Tasks

1. Add `Presentation/Canvas/PencilCanvasView`.
2. Bridge `PKCanvasView` into SwiftUI.
3. Bind `PKDrawing` to a view model without replacing the drawing during active strokes.
4. Set default `PKInkingTool(.fountainPen, color: .black, width: 2.4)`.
5. Add an editor screen that renders one page at A4 aspect ratio.
6. Load drawing data through `DrawingRepository`.
7. Save drawing data on change through an autosave entry point.
8. Add basic error display if drawing load/save fails.

## Acceptance Criteria

- User can write on the page with Apple Pencil on iPad.
- The default stroke is a PencilKit fountain pen.
- Page keeps A4 portrait ratio at different screen sizes.
- Existing drawing reloads after navigating away and back.
- Drawing survives app restart after autosave has run.

## Tests

- Simulator: editor screen renders and does not crash.
- Device: Apple Pencil writes with low visible latency.
- Device: close and relaunch app, confirm drawing persists.
- Device: finger scrolling does not unintentionally draw if Pencil-only policy is enabled.

## Risks

- Updating SwiftUI bindings too aggressively can reset `PKCanvasView` during drawing.
- PencilKit behavior must be judged on physical hardware, not simulator.
- The initial page frame may need tuning for zoom and pan ergonomics; detailed implementation is tracked in `05b-page-zoom-pan-optimization.md`.

## Definition of Done

- A real PencilKit A4 editor exists.
- Fountain pen is the default.
- Persistence round trip works for one page.
