# Exec Plan 06b: Fountain Pen

## Objective

Make the fountain pen feel intentional and configurable while staying inside native PencilKit.

## Context

The fountain pen is the app's primary identity and default writing tool. PencilKit exposes native fountain pen ink, color, width, and azimuth, but it does not expose a full custom nib/flatness renderer. This milestone must tune the best possible native PencilKit fountain pen and explicitly defer true custom nib rendering.

## Constraints

- Use `PKInkingTool(.fountainPen, ...)`.
- No custom renderer.
- Fountain pen remains black by default.
- Tool changes must not recreate the canvas.
- Settings must be represented in `DrawingToolPreset` or a compatible Presentation settings model.
- The main toolbar must show one fountain pen entry only; variants belong in settings opened from the selected tool.

## User Controls

- Width:
  - fine
  - medium
  - bold
  - optional continuous slider after presets work
- Color:
  - black default
  - small palette
  - custom color later if needed
- Nib orientation:
  - expose only if native `PKInkingTool` azimuth produces a meaningful visual difference on device
- Nib flatness:
  - represent as a future intent only; do not fake it unless PencilKit output clearly supports it.

## Tasks

1. Define fountain pen preset fields needed by MVP: color, width, optional azimuth.
2. Validate supported width range for fountain pen on iPad.
3. Build default fountain pen presets: fine, medium, bold.
4. If azimuth is useful, add named angle presets rather than a complex control.
5. Add UI metadata for selected fountain pen variant.
6. Keep the toolbar interaction model: first tap selects fountain pen, second tap opens fountain pen settings.
7. Ensure changing width/color/azimuth affects only future strokes.
8. Document that true nib flatness is out of scope until custom renderer research.

## Acceptance Criteria

- New notes start with black fountain pen selected.
- User can choose at least three fountain pen widths.
- The bottom toolbar does not show every fountain pen width as a separate top-level tool.
- Fountain pen changes apply to new strokes without changing existing strokes.
- If nib orientation is exposed, it has a visible effect on physical iPad.
- No UI suggests unsupported true nib flatness.

## Tests

- Unit: fountain pen presets map to `PKInkingTool.InkType.fountainPen`.
- Unit: invalid widths are clamped or rejected.
- Device: write slow lines, fast lines, curves, and pressure changes with each preset.
- Device: switch away and back to fountain pen; settings remain stable.

## Risks

- PencilKit may not expose enough control for user-visible nib flatness.
- Too many controls can make the first toolbar feel heavier than GoodNotes-style quick tools.

## Definition Of Done

- Fountain pen has deliberate presets.
- Black medium fountain pen remains the default.
- Native PencilKit limits are documented honestly.
