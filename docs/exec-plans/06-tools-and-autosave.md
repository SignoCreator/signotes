# Exec Plan 06: Tools and Autosave

## Objective

Add practical PencilKit tool switching and throttled autosave suitable for real note-taking.

## Context

PencilKit includes system inking, eraser, lasso, and a configurable tool picker. On iPadOS 18+, the tool picker can include system and custom items. The MVP should rely on native tools first and avoid duplicating complex system controls.

Relevant references:

- Configuring the PencilKit tool picker: https://developer.apple.com/documentation/PencilKit/configuring-the-pencilkit-tool-picker
- `PKEraserTool`: https://developer.apple.com/documentation/pencilkit/pkerasertool
- `PKLassoTool`: https://developer.apple.com/documentation/pencilkit/pklassotool
- Apple Pencil HIG: https://developer.apple.com/design/human-interface-guidelines/apple-pencil-and-scribble

## Constraints

- Fountain pen remains the default writing tool.
- Use native PencilKit tools where possible.
- Custom app toolbar should cover app-specific actions, not replicate every PencilKit control.
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
2. Configure a `PKToolPicker` for the active canvas.
3. Ensure native fountain pen preset is selected by default.
4. Add color and width persistence for inking tools if using custom presets.
5. Add an autosave coordinator with throttling/debouncing.
6. Save final drawing when the view disappears or app moves to background.
7. Show non-blocking save errors.
8. Add lightweight instrumentation logs for save timing during development.

## Acceptance Criteria

- User can switch among fountain pen, pen, pencil, marker, and eraser.
- Lasso works or is explicitly hidden until it works correctly.
- Autosave preserves drawing after relaunch.
- Autosave does not cause visible stutter during writing.
- Tool picker does not cover the writing area in an unusable way.

## Tests

- Device: write with each tool.
- Device: switch tools mid-session and continue writing.
- Device: force close after a recent stroke, relaunch, confirm save behavior.
- Simulator: tool picker appears without crashing.
- Manual timing: long continuous writing does not freeze UI.

## Risks

- Saving every `canvasViewDrawingDidChange` event can be too frequent.
- Tool picker state can desync if multiple canvases are introduced later.
- Some PencilKit picker customization may require iPadOS 18 availability guards.

## Definition of Done

- Tool switching is usable.
- Fountain pen is the default.
- Autosave is reliable and does not degrade writing feel.

