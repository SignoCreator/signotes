import SwiftUI

enum ToolPresetSettingsMode {
    case create
    case edit(DrawingToolPreset, canDelete: Bool)
}

struct ToolPresetSettingsPanel: View {
    let mode: ToolPresetSettingsMode
    let onSave: (String, DrawingToolKind, String, Double) async -> Void
    let onDelete: (() async -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var kind: DrawingToolKind
    @State private var colorHex: String
    @State private var width: Double
    @State private var autosaveTask: Task<Void, Never>?
    @State private var completedExplicitAction = false
    @FocusState private var isNameFocused: Bool

    init(
        mode: ToolPresetSettingsMode,
        onSave: @escaping (String, DrawingToolKind, String, Double) async -> Void,
        onDelete: (() async -> Void)?
    ) {
        self.mode = mode
        self.onSave = onSave
        self.onDelete = onDelete

        let preset: DrawingToolPreset
        switch mode {
        case .create:
            preset = DrawingToolPreset(name: "New pen", kind: .fountainPen)
        case let .edit(existingPreset, _):
            preset = existingPreset
        }

        _name = State(initialValue: preset.name)
        _kind = State(initialValue: preset.kind.isWritingTool ? preset.kind : .fountainPen)
        _colorHex = State(initialValue: preset.colorHex)
        _width = State(initialValue: preset.width)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ToolPresetSettingsHeader(
                        name: $name,
                        kind: kind,
                        colorHex: colorHex,
                        isNameFocused: $isNameFocused
                    )

                    ToolKindSelectionGrid(selection: $kind, colorHex: colorHex)

                    InkWidthControl(width: $width, colorHex: colorHex)

                    InkColorPaletteView(colorHex: $colorHex)
                }
                .padding(14)
            }

            if showsFooter {
                Divider()

                footer
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.regularMaterial)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(width: 390)
        .frame(maxHeight: 520)
        .onChange(of: name) { _, _ in
            scheduleAutosaveIfNeeded()
        }
        .onChange(of: kind) { _, _ in
            scheduleAutosaveIfNeeded()
        }
        .onChange(of: colorHex) { _, _ in
            scheduleAutosaveIfNeeded()
        }
        .onChange(of: width) { _, _ in
            scheduleAutosaveIfNeeded()
        }
        .onDisappear {
            autosaveTask?.cancel()
            guard !completedExplicitAction else {
                return
            }

            flushAutosaveIfNeeded()
        }
    }

    private var canDelete: Bool {
        if case let .edit(_, canDelete) = mode {
            return canDelete
        }

        return false
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isEditing: Bool {
        if case .edit = mode {
            return true
        }

        return false
    }

    private var showsFooter: Bool {
        !isEditing || (onDelete != nil && canDelete)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if let onDelete, canDelete {
                Button(role: .destructive) {
                    completedExplicitAction = true
                    autosaveTask?.cancel()
                    autosaveTask = nil

                    Task {
                        await onDelete()
                        dismiss()
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }

            Spacer()

            if !isEditing {
                Button {
                    completedExplicitAction = true

                    Task {
                        await onSave(trimmedName, kind, colorHex, width)
                        dismiss()
                    }
                } label: {
                    Label("Create", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(trimmedName.isEmpty)
            }
        }
    }

    private func scheduleAutosaveIfNeeded() {
        guard isEditing, !trimmedName.isEmpty else {
            autosaveTask?.cancel()
            autosaveTask = nil
            return
        }

        autosaveTask?.cancel()
        let name = trimmedName
        let kind = kind
        let colorHex = colorHex
        let width = width
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else {
                return
            }

            await onSave(name, kind, colorHex, width)
        }
    }

    private func flushAutosaveIfNeeded() {
        guard isEditing, !trimmedName.isEmpty else {
            return
        }

        Task {
            await onSave(trimmedName, kind, colorHex, width)
        }
    }

    private func flushAutosave() async {
        autosaveTask?.cancel()
        autosaveTask = nil

        guard isEditing, !trimmedName.isEmpty else {
            return
        }

        await onSave(trimmedName, kind, colorHex, width)
    }
}
