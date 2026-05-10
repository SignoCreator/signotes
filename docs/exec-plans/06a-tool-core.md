# Exec Plan 06a: Tool Core

## Objective

Create the shared tool architecture used by all editor tools without building a deep superclass hierarchy.

## Context

Swift value models and small factories fit this app better than inheritance. The app already has `DrawingToolPreset` in Domain and `EditorDrawingTool` in Presentation. This milestone reconciles those responsibilities so future tool-specific work does not duplicate state or hardcode PencilKit settings in UI views.

## Constraints

- Domain remains independent from SwiftUI, UIKit, PencilKit, and filesystem.
- Presentation converts domain/tool state into PencilKit tools.
- No custom renderer.
- Do not introduce `PKToolPicker`.
- Keep tool changes cheap: selecting a tool must only update `PKCanvasView.tool`.

## Target Responsibilities

- Domain:
  - `DrawingToolKind`
  - `DrawingToolPreset`
  - stable preset IDs
  - Codable value state for persistence
- Presentation:
  - `EditorToolState`
  - `EditorToolFactory`
  - UIKit color conversion
  - PencilKit `PKTool` creation
  - selected/previous tool behavior
- UI:
  - read state
  - dispatch tool selection/settings actions
  - no direct `PKInkingTool` construction

## Tasks

1. Audit `DrawingToolPreset`, `DrawingToolKind`, and `EditorDrawingTool`.
2. Decide whether `EditorDrawingTool` is removed or reduced to a UI adapter over `DrawingToolKind`.
3. Add a Presentation `EditorToolState` with selected preset ID, previous preset ID, and ordered presets.
4. Add `EditorToolFactory` that converts a `DrawingToolPreset` into `PKTool`.
5. Add color parsing helpers at the Presentation boundary.
6. Replace hardcoded tool creation in `EditorDrawingTool.makeTool()` with the factory path.
7. Keep the current visible toolbar working with the new model before tool-specific settings are added.

## Acceptance Criteria

- Domain tool models compile without UI/PencilKit imports.
- PencilKit creation exists only in Presentation.
- Default presets produce the same visible tools as the current app.
- Selecting a tool updates `PKCanvasView.tool` without recreating the canvas.
- Fountain pen remains the default selected preset.

## Tests

- Unit: default presets contain fountain pen, pen, pencil, marker, eraser, and lasso.
- Unit: preset IDs are stable.
- Unit: factory maps each preset kind to the expected PencilKit tool class/type.
- Device smoke: switching existing tools still works after the refactor.

## Risks

- A half-refactor can leave duplicate sources of truth.
- UI code may keep direct PencilKit assumptions unless explicitly removed.

## Definition Of Done

- Shared tool state is centralized.
- Tool-specific milestones can build on the same model/factory.
- No current tool behavior regresses.
