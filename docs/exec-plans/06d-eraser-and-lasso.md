# Exec Plan 06d: Eraser And Lasso

## Objective

Add non-inking tools cleanly: eraser and lasso.

## Context

Eraser and lasso are not ink tools. They should use the same toolbar selection model, but their settings and UI should not pretend they have color. Lasso must be enabled only if its behavior is reliable in the current `PKCanvasView` stack.

## Constraints

- Use native `PKEraserTool`.
- Use native `PKLassoTool` only if it integrates cleanly.
- No custom selection system.
- No custom eraser implementation.
- Color controls are hidden or disabled for non-inking tools.

## Tasks

1. Add eraser preset to the shared tool state.
2. Decide bitmap vs vector eraser behavior after device testing.
3. Add eraser size control only if native PencilKit supports the selected eraser mode cleanly.
4. Add lasso preset behind a clear availability/behavior check.
5. Make toolbar settings panel context-aware: eraser/lasso do not show ink controls.
6. Track previous writing tool so user can quickly return after erasing/selecting.

## Acceptance Criteria

- User can erase existing PencilKit strokes.
- Eraser selection does not show color controls.
- Lasso is either usable or hidden with a documented reason.
- Returning to the previous ink tool is predictable.
- Autosave persists erasures/selections that mutate the drawing.

## Tests

- Device: write, erase part/all of a stroke, relaunch, confirm persistence.
- Device: use eraser while zoomed.
- Device: lasso select/move/delete if enabled.
- Simulator: toolbar state changes do not crash without Apple Pencil.

## Risks

- Lasso behavior can feel broken if custom canvas layering intercepts gestures.
- Native eraser modes may not expose every setting users expect.

## Definition Of Done

- Eraser is production-usable.
- Lasso is either production-usable or intentionally deferred.
- Non-ink tools do not complicate ink preset state.
