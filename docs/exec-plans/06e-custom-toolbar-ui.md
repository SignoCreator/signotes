# Exec Plan 06e: Custom Toolbar UI

## Objective

Build the custom editor toolbar that replaces any dependency on the native PencilKit picker.

## Context

The toolbar is a primary part of the note-taking experience. It should be compact, native-feeling, and fast. It must expose tool selection first, then settings without covering the page in an intrusive way.

## Constraints

- Do not show `PKToolPicker`.
- Use app-owned tool state.
- Toolbar must not cover too much writing area.
- Toolbar must remain reachable while zoomed.
- UI components must be split by responsibility. A single large toolbar file is not acceptable once settings, icons, and preset management exist.
- The primary toolbar is top-mounted for the editor MVP, so it does not occupy the common bottom writing area.
- Tool settings popovers must be anchored to the tapped tool button, not centered on the whole toolbar.

## Proposed Components

- `EditorToolPaletteView`: composition, state routing, popover anchoring only.
- `EditorToolButton`: fixed-size accessible preset button.
- `AddToolPresetButton`: fixed-size add action.
- `ToolPresetSettingsPanel`: create/update form only.
- `InkColorPaletteView`: palette and custom color input.
- `InkWidthControl`: stroke width control and preview.
- `EditorToolIcon`: high-quality template icon assets for tool types; do not use weak generic symbols for fountain pen or eraser.

## UX Behavior

- The toolbar shows saved presets, not every possible tool/width combination.
- Tap an unselected preset to select it.
- Tap the selected writing preset again to open settings.
- Use a fixed target size for selected and unselected tools. Selection may change color/elevation, but must not move or resize the hit target.
- Add a visible `+` button to create a custom writing preset.
- Built-in presets can be edited but not deleted. Custom presets can be duplicated and deleted.
- Editing an existing preset auto-saves each valid change; the panel uses `Fine`, not an explicit `Salva` action.
- If the user creates many presets, the toolbar scrolls horizontally instead of overflowing the screen.
- Writing tool icons stay neutral until layered tip-color icons are implemented; use a compact color swatch for quick scanning.
- The toolbar uses a full-width top editor bar, closer to GoodNotes/OneNote than a floating pill.
- Tool controls are compact rounded-square targets; avoid oversized floating buttons.
- Settings panel is contextual:
  - ink tools: name, tool type, color, width, duplicate/delete where allowed
  - eraser: eraser mode/size if supported
  - lasso: no color/width controls
- Toolbar visually shows:
  - selected state
  - active color swatch for ink tools
  - active width if space allows

## Tasks

1. Replace current minimal `EditorToolPaletteView` with componentized toolbar files.
2. Add tool buttons with stable dimensions and accessibility labels.
3. Add selected-tool settings panel anchored to the tapped tool.
4. Add preset creation with a visible add button.
5. Add color palette, custom color picker, width control, name, and tool type for writing tools.
6. Add duplicate/delete actions with delete limited to custom presets.
7. Hide irrelevant controls for eraser/lasso.
8. Keep the toolbar top-mounted unless device testing proves it conflicts with navigation.
9. Ensure toolbar layout works in portrait and landscape.

## Acceptance Criteria

- Toolbar is fully custom and does not show native PencilKit picker.
- User can switch tools with one tap.
- User can open settings for the selected tool.
- User can add, modify, duplicate, and remove custom writing presets.
- Fountain pen uses a recognizable nib icon, not a generic pen symbol.
- Eraser uses a recognizable high-quality icon that is visually consistent with the ink tools.
- Existing preset edits apply without a separate save step.
- Adding many presets does not push the toolbar outside the viewport.
- Ink presets expose color through a compact swatch until `06g` implements tip-only icon coloring.
- Toolbar controls use compact rounded-square buttons inside a full-width top bar.
- Settings open from the tapped tool, not from the center of the toolbar.
- Toolbar text/icons do not overlap on iPad portrait or landscape.
- Selected and unselected tools keep the same touch target size.
- Toolbar does not recreate `PKCanvasView`.
- The design feels like a focused editor control, not a decorative card.

## Tests

- Simulator: toolbar renders in portrait/landscape.
- Device: switch tools while writing.
- Device: open settings while zoomed and continue writing.
- Device: verify toolbar does not block common bottom-page writing too aggressively.

## Risks

- A large settings panel can feel worse than the system picker.
- Over-customizing too early can slow down the MVP.

## Definition Of Done

- Toolbar is componentized, usable, and visually consistent.
- Tool settings are discoverable without making the writing surface feel cramped.
