# Exec Plan 06c: Standard Ink Tools

## Objective

Implement configurable native PencilKit presets for pen, pencil, and marker.

## Context

These tools share common ink controls: color, width, and selected preset. They should reuse the tool core instead of introducing separate ad hoc code paths.

## Constraints

- Use native `PKInkingTool` types: `.pen`, `.pencil`, `.marker`.
- No native `PKToolPicker`.
- No custom renderer.
- Do not let marker settings pollute pen/pencil settings.
- Tool controls must stay fast enough to change while taking notes.

## Tool Defaults

- Pen:
  - black
  - medium width
- Pencil:
  - dark gray
  - medium sketch width
- Marker:
  - yellow
  - wide width
  - opacity handled through color alpha if needed

## Tasks

1. Define shared ink settings: color, width, opacity where applicable.
2. Add default presets for pen, pencil, and marker.
3. Add allowed width ranges per tool kind.
4. Add a small shared color palette.
5. Add marker-specific palette colors: yellow, green, blue, pink, orange.
6. Ensure each tool remembers its own last settings.
7. Ensure selected tool swatch reflects the active preset.

## Acceptance Criteria

- User can write with pen, pencil, and marker.
- User can change color and width for each ink tool.
- Marker remains visibly marker-like and does not become the default writing tool.
- Switching between tools restores the last settings for that tool.
- Existing handwriting is not mutated when settings change.

## Tests

- Unit: each tool kind maps to the expected PencilKit ink type.
- Unit: color hex conversion handles alpha where used.
- Device: write with each tool and change settings mid-session.
- Device: switch tools repeatedly while zoomed and confirm no canvas recreation/lag.

## Risks

- Marker opacity may behave differently from simple UIKit alpha because PencilKit also varies final opacity with Pencil input.
- Too many colors can clutter the toolbar.

## Definition Of Done

- Pen, pencil, and marker are configurable through the shared tool core.
- Their UI behavior is consistent but tool-specific defaults remain distinct.
