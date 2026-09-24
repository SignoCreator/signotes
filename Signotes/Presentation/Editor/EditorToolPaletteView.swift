import SwiftUI

struct EditorToolPaletteView: View {
    @Binding var selectedTemplate: PageTemplate
    let onTogglePageOverview: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let commandAvailability: EditorCanvasCommandAvailability
    @Binding var toolState: EditorToolState
    let onCreatePreset: (String, DrawingToolKind, String, Double) async -> Void
    let onUpdatePreset: (UUID, String, DrawingToolKind, String, Double) async -> Void
    let onDeletePreset: (UUID) async -> Void
    @Environment(\.colorScheme) private var colorScheme

    @State private var settingsPresetID: UUID?
    @State private var isCreatingPreset = false
    @State private var isTemplatePickerPresented = false

    var body: some View {
        HStack(alignment: .bottom, spacing: EditorToolbarMetrics.sectionSpacing) {
            ToolbarCommandButton(
                systemName: "rectangle.grid.2x2",
                label: "Pages",
                isEnabled: true,
                action: onTogglePageOverview
            )

            ToolbarSectionDivider()

            HStack(alignment: .bottom, spacing: EditorToolbarMetrics.commandSpacing) {
                ToolbarCommandButton(
                    systemName: "arrow.uturn.backward",
                    label: "Undo",
                    isEnabled: commandAvailability.canUndo,
                    action: onUndo
                )
                ToolbarCommandButton(
                    systemName: "arrow.uturn.forward",
                    label: "Redo",
                    isEnabled: commandAvailability.canRedo,
                    action: onRedo
                )
            }

            ToolbarSectionDivider()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: EditorToolbarMetrics.toolSpacing) {
                    toolPresetButtons

                    ToolbarSectionDivider()
                        .padding(.horizontal, 2)

                    addToolButton
                }
                .padding(.horizontal, 1)
                .frame(minHeight: 64, alignment: .bottom)
            }
            .contentMargins(.horizontal, 0, for: .scrollContent)
            .frame(maxWidth: .infinity)

            ToolbarSectionDivider()

            PageTemplateToolButton(
                selectedTemplate: $selectedTemplate,
                isPresented: $isTemplatePickerPresented
            )
        }
        .padding(.horizontal, EditorToolbarMetrics.outerPadding)
        .frame(height: EditorToolbarMetrics.height)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.07))
                .frame(height: 1)
        }
    }

    private func handleToolTap(_ preset: DrawingToolPreset) {
        guard toolState.isSelected(id: preset.id) else {
            toolState.selectPreset(id: preset.id)
            return
        }

        if preset.kind.isWritingTool {
            settingsPresetID = preset.id
        }
    }

    @ViewBuilder
    private var toolPresetButtons: some View {
        ForEach(toolState.toolbarPresets) { preset in
            EditorToolButton(
                preset: preset,
                isSelected: toolState.isSelected(id: preset.id),
                action: {
                    handleToolTap(preset)
                }
            )
            .popover(
                isPresented: Binding(
                    get: { settingsPresetID == preset.id },
                    set: { isPresented in
                        if !isPresented, settingsPresetID == preset.id {
                            settingsPresetID = nil
                        }
                    }
                ),
                arrowEdge: .top
            ) {
                if let currentPreset = toolState.preset(id: preset.id), currentPreset.kind.isWritingTool {
                    ToolPresetSettingsPanel(
                        mode: .edit(currentPreset, canDelete: toolState.canDeletePreset(id: currentPreset.id)),
                        onSave: { name, kind, colorHex, width in
                            await onUpdatePreset(currentPreset.id, name, kind, colorHex, width)
                        },
                        onDelete: {
                            await onDeletePreset(currentPreset.id)
                        }
                    )
                    .presentationCompactAdaptation(.popover)
                }
            }
        }
    }

    private var addToolButton: some View {
        AddToolPresetButton {
            isCreatingPreset = true
        }
        .popover(isPresented: $isCreatingPreset, arrowEdge: .top) {
            ToolPresetSettingsPanel(
                mode: .create,
                onSave: { name, kind, colorHex, width in
                    await onCreatePreset(name, kind, colorHex, width)
                },
                onDelete: nil
            )
            .presentationCompactAdaptation(.popover)
        }
    }
}
