# Exec Plan 06g: Tool Icon Design Refinement

## Objective

Replace the current toolbar icon treatment with custom, polished tool icons where only the physical writing tip reflects the selected ink color.

## Context

The current toolbar proves the interaction model, but the icon style is not good enough. Tinting the full icon with the preset color makes the tool silhouette less realistic and visually noisy. The next iteration should make each tool feel like a real pen/pencil/marker object: mostly neutral body, color only on the nib/tip/ink contact area.

## Constraints

- Keep `EditorToolIcon` as the icon rendering boundary.
- Do not scatter icon-specific rendering logic inside `EditorToolButton`.
- Icons must remain readable at compact toolbar size.
- Icons must support dark mode and light mode.
- Icons must not rely on one-color template rendering for writing tools.
- The selected ink color should affect only the tip/nib/marker stroke area, not the whole icon body.
- Eraser and lasso do not use ink color.
- Do not regress accessibility labels or button hit targets.

## Proposed Components

- `EditorToolIcon`: route each tool kind to a multi-layer icon renderer.
- `WritingToolIcon`: shared wrapper for neutral body plus colored tip.
- `FountainPenIcon`, `PenIcon`, `PencilIcon`, `MarkerIcon`: tool-specific layered icons.
- `NeutralToolIcon`: eraser/lasso handling.

## UX Behavior

- The toolbar still shows one compact button per preset.
- Writing tool icons show a neutral body and a colored writing tip.
- The color swatch can remain as a secondary scan aid only if device testing shows the colored tip is not enough.
- Changing ink color updates the tip immediately in the toolbar and settings panel.
- Selection state must not recolor the entire icon.

## Tasks

1. Replace full-template tinting for writing tools with layered icons.
2. Decide whether icons should be repo-native SwiftUI shapes, custom SVG/PDF assets, or multi-layer asset catalog images.
3. Implement fountain pen, pen, pencil, and marker with a neutral body and colorable tip.
4. Keep eraser and lasso neutral and visually consistent.
5. Update toolbar button selected state so it does not hide the tool color.
6. Validate icon readability at normal and compact iPad toolbar sizes.
7. Update third-party attribution only if external assets remain in use.
8. Remove obsolete icon assets if replaced.

## Acceptance Criteria

- Only the writing tip/nib/marker edge is colored with the preset ink color.
- The rest of the icon remains neutral and legible in light/dark mode.
- Fountain pen and normal pen are visually distinct.
- Icons do not look pixelated or low quality on physical iPad.
- Toolbar does not overflow when many presets exist.
- Settings panel preview matches the toolbar icon behavior.
- No one-color full-icon tint remains for writing tools.

## Tests

- Simulator: verify toolbar icons in light and dark mode.
- Simulator: add many presets and confirm horizontal scrolling still works.
- Device: change preset color and confirm only the tip updates.
- Device: verify icons are readable at real iPad scale.
- Device: write with each tool after changing icon rendering to confirm PencilKit tool mapping is unchanged.

## Risks

- Too much detail can become unreadable at toolbar size.
- External icon packs may not expose separate body/tip layers, requiring custom vector work.
- Colored tips may be too subtle for quick scanning, so the swatch may need to stay.

## Definition Of Done

- Writing tool icons are layered, polished, and color only the tip.
- Existing tool selection, creation, edit, autosave, and PencilKit behavior are unchanged.
- Device QA confirms the icons feel better than the current full-tint version.
