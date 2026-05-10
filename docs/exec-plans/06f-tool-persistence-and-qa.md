# Exec Plan 06f: Tool Persistence And QA

## Objective

Persist tool state and validate the full toolbar/tool/autosave experience on physical iPad.

## Context

Tool settings are only useful if they survive navigation and relaunch. Persistence must not happen on the hot drawing path, and QA must focus on Apple Pencil feel rather than simulator-only correctness.

## Constraints

- Persist tool presets separately from drawing blobs.
- Do not block active PencilKit input while saving tool preferences.
- Do not couple tool preference storage to note drawing storage.
- Preserve existing notes and drawings.

## Persistence Scope

- selected tool ID
- previous tool ID where useful
- ordered presets
- per-tool last color/width/settings
- toolbar preference state only if it improves UX

## Tasks

1. Choose persistence location for editor tool preferences.
2. Add repository/protocol if needed instead of writing directly from UI.
3. Load tool preferences when editor opens.
4. Save changed tool preferences automatically with debounce; avoid explicit save buttons for existing presets.
5. Ensure drawing autosave and tool preference save are separate flows.
6. Add manual QA checklist for long writing sessions.
7. Add regression tests for preference load/save.

## Acceptance Criteria

- Relaunch preserves last selected tool and configured presets.
- Drawing autosave still persists handwriting reliably.
- Tool preference save does not create visible writing stutter.
- Existing users without preference data get default presets.
- Corrupt preference data falls back safely and surfaces a non-blocking error only if useful.

## Tests

- Unit: preference encode/decode round trip.
- Unit: missing preference file returns defaults.
- Unit: corrupt preference file falls back safely.
- Device: configure tools, relaunch, verify state.
- Device: write continuously for several minutes and observe latency.
- Device: switch tools during a long note and confirm persistence.

## Risks

- Saving preferences too often can reintroduce latency.
- Preset migration needs care once users customize tools.

## Definition Of Done

- Tool preferences are persistent and migration-ready.
- Autosave and tool preference persistence remain separate.
- Physical iPad QA confirms no obvious stutter from toolbar/tool changes.
