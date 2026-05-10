# Exec Plan 06: Custom Tools And Autosave

## Objective

Replace the current minimal tool switcher with a custom, scalable editor toolbar built on PencilKit tools, while keeping autosave reliable and handwriting low-latency.

## Context

This is now a multi-milestone track. The editor must not grow one large view/model that owns every tool detail. Shared concepts go into a tool core; each tool family gets its own milestone and acceptance criteria.

PencilKit remains the MVP rendering engine. A proprietary renderer is intentionally out of scope for this track.

Relevant references:

- PencilKit: https://developer.apple.com/documentation/pencilkit
- `PKInkingTool`: https://developer.apple.com/documentation/pencilkit/pkinkingtool-swift.struct
- `PKInkingTool.width`: https://developer.apple.com/documentation/pencilkit/pkinkingtoolreference/width
- `PKEraserTool`: https://developer.apple.com/documentation/pencilkit/pkerasertool
- `PKLassoTool`: https://developer.apple.com/documentation/pencilkit/pklassotool
- Apple Pencil HIG: https://developer.apple.com/design/human-interface-guidelines/apple-pencil-and-scribble

## Plan Split

Execute in this order:

1. `06a-tool-core.md`
2. `06b-fountain-pen.md`
3. `06c-standard-ink-tools.md`
4. `06d-eraser-and-lasso.md`
5. `06e-custom-toolbar-ui.md`
6. `06f-tool-persistence-and-qa.md`

## Global Constraints

- Fountain pen remains the default writing tool.
- Use native PencilKit tools where possible.
- Do not show the native `PKToolPicker` in the MVP editor.
- Custom editor toolbar owns visible tool switching and tool settings.
- Autosave must not block active drawing.
- Tool switching must not recreate `PKCanvasView`.
- No custom renderer work in this track.

## Definition Of Done

- Tool model, toolbar UI, tool-specific settings, and autosave have clear ownership.
- User can write with fountain pen, pen, pencil, marker, eraser, and lasso where supported.
- The toolbar is fully custom and does not depend on `PKToolPicker`.
- Fountain pen is the default.
- Autosave remains reliable and does not degrade writing feel.
