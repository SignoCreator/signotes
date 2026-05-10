import Foundation

struct EditorToolState: Equatable {
    var presets: [DrawingToolPreset]
    var selectedPresetID: UUID
    var previousPresetID: UUID?

    init(
        presets: [DrawingToolPreset] = DrawingToolPreset.defaults,
        selectedPresetID: UUID = DrawingToolPreset.defaultFountainPenID,
        previousPresetID: UUID? = nil
    ) {
        self.presets = presets
        self.selectedPresetID = selectedPresetID
        self.previousPresetID = previousPresetID
    }

    var selectedPreset: DrawingToolPreset {
        preset(id: selectedPresetID) ?? presets.first ?? DrawingToolPreset.defaultFountainPen
    }

    var toolbarPresets: [DrawingToolPreset] {
        presets
    }

    func preset(id: UUID) -> DrawingToolPreset? {
        presets.first { $0.id == id }
    }

    func presets(kind: DrawingToolKind) -> [DrawingToolPreset] {
        presets.filter { $0.kind == kind }
    }

    func isSelected(kind: DrawingToolKind) -> Bool {
        selectedPreset.kind == kind
    }

    func isSelected(id: UUID) -> Bool {
        selectedPresetID == id
    }

    func canDeletePreset(id: UUID) -> Bool {
        guard let preset = preset(id: id), !preset.isBuiltIn else {
            return false
        }

        if preset.isWritingTool {
            return presets.contains { $0.id != id && $0.isWritingTool }
        }

        return true
    }

    mutating func syncPresets(_ newPresets: [DrawingToolPreset]) {
        presets = newPresets.isEmpty ? DrawingToolPreset.defaults : newPresets

        guard preset(id: selectedPresetID) == nil else {
            return
        }

        previousPresetID = selectedPresetID
        selectedPresetID = presets.first?.id ?? DrawingToolPreset.defaultFountainPenID
    }

    mutating func selectPreset(id: UUID) {
        guard id != selectedPresetID, preset(id: id) != nil else {
            return
        }

        previousPresetID = selectedPresetID
        selectedPresetID = id
    }

    mutating func selectToolKind(_ kind: DrawingToolKind) {
        guard let preset = presets.first(where: { $0.kind == kind }) else {
            return
        }

        selectPreset(id: preset.id)
    }
}
