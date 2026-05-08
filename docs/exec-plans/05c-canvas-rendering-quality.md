# Exec Plan 05c: Canvas Rendering Quality

## Objective

Make zoomed handwriting render with vector-like sharpness and remove visible ink pixelation while keeping PencilKit as the MVP handwriting engine.

## Context

The current editor uses a SwiftUI-hosted page inside an outer `UIScrollView` zoom container. That is convenient for layout, but it can make PencilKit handwriting look raster-scaled when zooming because the full hosted view may be transformed as a layer instead of redrawn at the new zoom detail.

PencilKit stores drawings as structured `PKDrawing` data, not as a baked bitmap. The rendering path must preserve that quality on screen by avoiding accidental rasterization of the page/canvas stack.

This plan is connected to:

- Exec Plan 05b zoom/pan behavior.
- Exec Plan 05 page templates, because ruled/grid/dotted backgrounds must stay sharp and aligned.
- Exec Plan 06 custom tool palette, because tool switching must keep working after replacing the canvas container.
- Future export/render work, because templates plus handwriting must eventually compose without quality loss.
- Future custom renderer research, but this milestone must not replace PencilKit.

## Constraints

- Keep PencilKit as the handwriting and persistence engine.
- Do not implement a proprietary ink renderer in this milestone.
- Do not reintroduce the native PencilKit tool picker.
- Do not rasterize handwriting or the full A4 page for normal editing.
- Apple Pencil writing must remain low-latency on physical iPad.
- Zoom, pan, rotate, template changes, autosave, and tool switching must not mutate drawing data.
- Background and handwriting must share one page coordinate system.

## Technical Direction

Replace the current SwiftUI-hosted zoom stack with a native canvas container that owns page geometry and zoom rendering.

Target shape:

- `PencilPageCanvasView`: UIKit-backed page editor container.
- Owns a `UIScrollView` or uses `PKCanvasView` scroll/zoom behavior directly after spike validation.
- Hosts `PKCanvasView` without scaling it as an already-rendered SwiftUI layer.
- Hosts page template background as a vector/redrawable UIKit or SwiftUI-backed layer that stays aligned with the PencilKit content.
- Keeps `PKCanvasView.maximumSupportedContentVersion = .version3`.
- Applies selected tools directly through `PKCanvasView.tool` from the custom palette.

The implementation must explicitly choose one zoom owner:

- Preferred if quality is good: `PKCanvasView`/native scroll behavior owns zoom and content size.
- Fallback if needed: one outer UIKit `UIScrollView` owns zoom, but the zoomed content must be structured so PencilKit and background redraw cleanly and do not blur.

## Connected Work To Include

- Audit `UIViewRepresentable` update cycles so `PKCanvasView` is not recreated during zoom, pan, or active strokes.
- Keep active zoom and active stroke state inside UIKit; SwiftUI must not receive per-frame zoom updates or per-stroke drawing publications.
- Treat `PKDrawing.dataRepresentation()` as a persistence boundary operation, not as a hot-path equality check during canvas updates.
- Remove unnecessary `UIHostingController` wrapping from the hot canvas path if it contributes to raster scaling.
- Ensure `contentScaleFactor`, layer rasterization flags, and transform usage do not force bitmap scaling.
- Do not override `PKCanvasView`'s `contentScaleFactor` or layer scale for zoom quality; PencilKit must own its own high-performance rendering path.
- Verify template backgrounds are vector-like at high zoom.
- Keep page shadow/chrome outside the zoomed drawing surface if it causes rasterization or unnecessary redraw cost.
- Preserve existing autosave behavior and avoid extra saves during pure zoom/pan.
- Throttle drawing-change delivery to persistence so autosave bookkeeping does not run on every PencilKit micro-update.
- Preserve selected tool state when rotating, navigating away, and returning.
- Add a clear code comment documenting canvas/zoom ownership once implemented.

## Tasks

1. Reproduce and document the current pixelation behavior on physical iPad at fit, 2x, and max zoom.
2. Audit `ZoomablePageScrollView`, `PageCanvasView`, and `PencilCanvasRepresentable` for layer scaling, view recreation, and geometry duplication.
3. Prototype `PencilPageCanvasView` as a UIKit-owned container behind a `UIViewRepresentable`.
4. Move page geometry into one shared configuration used by canvas, background, scroll bounds, and hit testing.
5. Render page templates in a redrawable vector path, not as a pre-rendered image.
6. Keep custom tool palette integration by applying `EditorDrawingTool.makeTool()` directly to the active `PKCanvasView`.
7. Confirm autosave only reacts to drawing changes, not zoom/pan changes.
8. Ensure drawing changes schedule persistence without publishing the full drawing back through SwiftUI on every stroke.
9. Tune min/max zoom and content insets on portrait and landscape iPad.
10. Remove or simplify obsolete zoom wrappers after the new canvas path is stable.
11. Add regression tests for geometry calculations and update-cycle behavior where practical.

## Acceptance Criteria

- Handwriting remains visually sharp at fit, 2x, and max zoom on physical iPad.
- No visible ink pixelation after writing, zooming, panning, and stopping the stroke.
- Grid, ruled, dotted, and blank templates stay sharp and aligned with handwriting.
- Apple Pencil input remains responsive while zoomed.
- Pinch zoom does not stutter due to SwiftUI state invalidation or drawing serialization on the hot path.
- Finger pan and pinch zoom remain usable.
- Tool palette still changes fountain pen, pen, pencil, marker, eraser, and lasso where supported.
- Autosave still persists drawing after relaunch.
- Template changes do not erase handwriting.
- Rotation does not cause the page to jump unexpectedly or reset in a surprising way.

## Tests

- Unit: page geometry maps A4 size, content size, zoom scale, and inset consistently.
- Unit: zoom clamp keeps values inside the supported range.
- Unit: tool selection still maps to the expected PencilKit tool.
- Simulator: editor opens, zoom reset works, templates change, and no native tool picker appears.
- Device: write at fit, 2x, and max zoom; inspect ink sharpness after each stroke.
- Device: write, zoom in/out repeatedly, pan, rotate, navigate away, return, verify alignment and persistence.
- Device: switch tools while zoomed and confirm the active tool changes without showing the native picker.
- Device: long writing session with repeated zoom/pan; observe latency and memory growth.

## Risks

- PencilKit may still internally cache some rendered tiles; quality must be judged on physical iPad, not only simulator.
- Gesture ownership can regress if `UIScrollView`, `PKCanvasView`, and SwiftUI all compete for touch handling.
- A UIKit-first editor container can increase complexity, so responsibilities must be isolated.
- Background rendering can drift if it does not use the same content coordinate space as PencilKit.
- Over-frequent SwiftUI state updates during zoom can hurt latency even if rendering quality improves.

## Definition of Done

- The editor has a single documented canvas/zoom owner.
- Zoomed ink looks sharp on physical iPad.
- Background templates remain sharp and aligned.
- Custom tool palette, autosave, navigation, and rotation still work.
- Obsolete zoom wrappers are removed or clearly isolated from the hot drawing path.
