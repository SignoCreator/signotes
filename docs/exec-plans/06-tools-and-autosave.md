# Exec Plan 06: Tools and Autosave

## Objective

Add practical PencilKit tool switching and throttled autosave suitable for real note-taking.

## Context

PencilKit includes system inking, eraser, lasso, and a configurable tool picker. The MVP should rely on native PencilKit drawing primitives, but the editor tool UI is fully custom: the app palette is the source of truth and the native PencilKit picker must remain hidden.

Relevant references:

- Configuring the PencilKit tool picker: https://developer.apple.com/documentation/PencilKit/configuring-the-pencilkit-tool-picker
- `PKEraserTool`: https://developer.apple.com/documentation/pencilkit/pkerasertool
- `PKLassoTool`: https://developer.apple.com/documentation/pencilkit/pklassotool
- Apple Pencil HIG: https://developer.apple.com/design/human-interface-guidelines/apple-pencil-and-scribble

## Constraints

- Fountain pen remains the default writing tool.
- Use native PencilKit tools where possible.
- Do not show the native `PKToolPicker` in the MVP editor.
- Custom editor palette owns visible tool switching.
- Autosave must not block active drawing.
- Lasso is included only if it integrates cleanly with current `PKCanvasView` selection behavior.

## Tool Presets

- Fountain pen: `PKInkingTool(.fountainPen, ...)`.
- Pen: `PKInkingTool(.pen, ...)`.
- Pencil: `PKInkingTool(.pencil, ...)`.
- Marker: `PKInkingTool(.marker, ...)`.
- Eraser: `PKEraserTool`.
- Lasso: `PKLassoTool`.

## Tasks

1. Introduce a tool state model in Presentation.
2. Apply the selected custom palette tool directly to `PKCanvasView.tool`.
3. Ensure native fountain pen preset is selected by default.
4. Add color and width persistence for inking tools if using custom presets.
5. Add an autosave coordinator with throttling/debouncing.
6. Save final drawing when the view disappears or app moves to background.
7. Show non-blocking save errors.
8. Add lightweight instrumentation logs for save timing during development.

## Acceptance Criteria

- User can switch among fountain pen, pen, pencil, marker, and eraser.
- Lasso works or is explicitly hidden until it works correctly.
- Native PencilKit tool picker is not visible while writing.
- Autosave preserves drawing after relaunch.
- Autosave does not cause visible stutter during writing.
- Custom palette remains usable and does not cover the writing area in an unusable way.

## Tests

- Device: write with each tool.
- Device: switch tools mid-session and continue writing.
- Device: force close after a recent stroke, relaunch, confirm save behavior.
- Simulator: custom palette appears without crashing.
- Manual timing: long continuous writing does not freeze UI.

## Risks

- Saving every `canvasViewDrawingDidChange` event can be too frequent.
- Custom palette state can desync if multiple canvases are introduced later without a clear editor-level source of truth.
- Some PencilKit picker customization may require iPadOS 18 availability guards.

## Definition of Done

- Tool switching is usable.
- Fountain pen is the default.
- Autosave is reliable and does not degrade writing feel.
