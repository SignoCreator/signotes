# Exec Plan 08: Custom Renderer Research

## Objective

Research a proprietary fountain pen renderer as a separate spike, without replacing PencilKit in the MVP.

## Context

PencilKit is the correct MVP renderer because it provides low-latency input, native inks, eraser, lasso, persistence, and platform integration. A custom renderer is useful only if Signotes needs a fountain pen feel that PencilKit cannot provide.

Relevant references:

- Handling input from Apple Pencil: https://developer.apple.com/documentation/uikit/handling-input-from-apple-pencil
- Getting high-fidelity input with coalesced touches: https://developer.apple.com/documentation/ApplePencil/getting-high-fidelity-input-with-coalesced-touches
- `UITouch` Apple Pencil attributes: https://developer.apple.com/documentation/uikit/uitouch
- `PKStrokePath`: https://developer.apple.com/documentation/pencilkit/pkstrokepath

## Constraints

- This is a research spike, not production implementation.
- Do not remove PencilKit.
- Do not store custom strokes as the main note format until export, eraser, lasso, undo/redo, and migration are understood.
- Prototype can live behind a feature flag or separate debug screen.

## Research Questions

- Can the app capture enough data for a convincing fountain pen?
- Which input data is stable on the target iPads?
- How much latency does smoothing add?
- Does barrel roll meaningfully improve nib orientation on Pencil Pro?
- Can output remain vector-like for zoom and PDF export?

## Input Data to Capture

- Location.
- Timestamp.
- Phase.
- Force and maximum force.
- Altitude angle.
- Azimuth angle and unit vector.
- Roll angle where supported.
- Coalesced touches.
- Predicted touches if used for latency masking.
- Estimated property updates for force, altitude, azimuth, and roll.

## Prototype Approach

1. Build a debug-only raw input capture view.
2. Record stroke samples to an in-memory model.
3. Render a simple variable-width stroke.
4. Add smoothing and compare latency.
5. Add nib angle response from azimuth/altitude.
6. Add optional roll response on supported hardware.
7. Compare output against PencilKit fountain pen with the same writing samples.
8. Produce a recommendation: keep PencilKit, build hybrid, or invest in custom engine.

## Acceptance Criteria

- Research prototype captures and displays input data.
- Prototype renders at least one variable-width fountain-pen-like stroke.
- Findings document lists latency, quality, missing features, and implementation cost.
- No production editor path depends on the prototype.

## Tests

- Device: record slow, fast, light, and heavy strokes.
- Device: record low-altitude and high-altitude strokes.
- Pencil Pro if available: record roll changes.
- Compare visual samples against PencilKit fountain pen.
- Confirm prototype can be disabled with no user-facing effect.

## Risks

- A convincing renderer is likely 7/10 difficulty; Goodnotes-level feel is closer to 9/10.
- Custom eraser, selection, undo/redo, hit-testing, and PDF export are separate hard problems.
- Input APIs can provide estimated values that update later; the renderer must handle corrections.

## Definition of Done

- Research output exists as a written recommendation.
- Prototype demonstrates feasibility or clearly explains blockers.
- PencilKit remains the production MVP renderer.

