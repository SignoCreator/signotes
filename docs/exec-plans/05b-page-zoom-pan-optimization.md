# Exec Plan 05b: Page Zoom, Pan, and Canvas Optimization

## Objective

Add a production-quality zoom and pan experience for the A4 editor, while keeping Apple Pencil writing low-latency and the canvas memory footprint predictable.

## Context

The MVP editor already uses PencilKit for handwriting. Page templates add visual paper backgrounds. This milestone makes the editor comfortable for real note-taking by allowing users to zoom into details, pan around the page, and return to a fit-to-width view without degrading Apple Pencil input.

## Constraints

- Keep PencilKit as the handwriting engine.
- Do not introduce a custom renderer in this milestone.
- Physical iPad testing is required for Apple Pencil plus touch gesture behavior.
- Zoom state must not mutate drawing data.
- Page background, drawing, and overlays must stay visually aligned at every zoom level.
- Prefer native `PKCanvasView` and `UIScrollView` behavior where it gives reliable Pencil latency and gesture handling.

## UX Behavior

- Editor opens with the A4 page fit to width.
- Pinch zoom changes page scale smoothly.
- Finger pan moves around the zoomed page.
- Apple Pencil writes without the page moving unexpectedly.
- A visible reset/fit control returns to fit-to-width.
- Zoom limits prevent unusable extremes.
- Navigation and tool controls remain reachable while zoomed.

## Technical Approach

1. Audit the current `PencilCanvasView` and editor layout.
2. Decide whether to use `PKCanvasView`'s inherited `UIScrollView` zoom behavior directly or a surrounding scroll/zoom coordinator.
3. Keep one source of truth for page geometry: A4 aspect ratio, rendered page size, content inset, and zoom scale.
4. Align `PageBackgroundView` and `PKCanvasView` using the same page bounds.
5. Add a lightweight `CanvasViewportState` or equivalent Presentation model for current zoom, min zoom, max zoom, and fit-to-width calculation.
6. Persist zoom only if it improves user experience without surprising note reopening; default decision is session-only state.

## Optimization Requirements

- Avoid recreating `PKCanvasView` during zoom, pan, or active strokes.
- Do not replace `PKDrawing` while the user is writing.
- Throttle any viewport persistence separately from drawing autosave.
- Keep template backgrounds vector-based and cheap to redraw.
- Do not rasterize the full A4 page at high zoom unless a measured performance issue requires it.
- Clamp zoom to a practical range, currently `fitToWidth...8x`, then tune on iPad.
- Treat the maximum zoom as product configuration, not a permanent hardcoded constant.
- Avoid unnecessary SwiftUI layout invalidations while the user pans.
- Measure with real device observation: stroke latency, dropped frames during pinch, memory growth after repeated zoom/write/navigation cycles.

## Tasks

1. Add an exec note in the editor code documenting the chosen scroll/zoom ownership.
2. Implement fit-to-width initial scale for portrait and landscape iPad.
3. Add pinch-to-zoom and finger pan behavior.
4. Add a compact fit/reset zoom control in the editor chrome.
5. Ensure Pencil input remains prioritized over finger drawing.
6. Keep page template background aligned under PencilKit at every scale.
7. Add ViewModel or coordinator tests for zoom clamp and fit calculations where possible.
8. Add manual device smoke tests for Pencil, pan, pinch, rotate, and relaunch.
9. Follow-up: expose maximum zoom as an editor/app preference with validated presets, for example 4x, 6x, and 8x.

## Acceptance Criteria

- Page opens fit-to-width on iPad.
- User can pinch to zoom and finger-pan the page.
- Apple Pencil writing remains responsive while zoomed.
- Page template background and handwriting stay aligned.
- Fit/reset control returns to the expected scale.
- Current max zoom reaches 8x without background/ink drift at the limit.
- Zooming does not erase or mutate drawing data.
- No obvious memory growth after repeated zoom/write/navigation cycles.

## Tests

- Unit: fit-to-width scale calculation for representative viewport sizes.
- Unit: zoom clamp rejects values below min and above max.
- Simulator: editor renders at default scale and reset control works.
- Device: pinch zoom, finger pan, Apple Pencil writing at 1x, 2x, and max zoom.
- Device: rotate portrait/landscape and confirm page remains usable.
- Device: write, zoom, navigate away, return, confirm drawing persists and page is aligned.

## Risks

- Gesture conflicts between PencilKit drawing, finger scrolling, and SwiftUI gestures can feel inconsistent.
- Rebuilding the wrapped UIKit view from SwiftUI state changes can hurt latency.
- Large drawings can increase memory use when combined with high zoom.
- Background rendering may drift if page geometry is duplicated across views.

## Definition of Done

- Zoom and pan are implemented with clear ownership.
- Apple Pencil remains the primary, responsive input path.
- Page geometry is shared consistently by background and drawing canvas.
- Optimization constraints are documented and verified on physical iPad.

## Follow-Up

- If handwriting appears pixelated while zoomed, execute `05c-canvas-rendering-quality.md` before expanding editor features. Zoom UX is not considered production-quality until the rendered ink and paper templates remain sharp at high zoom on physical iPad.
