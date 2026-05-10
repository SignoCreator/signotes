import SwiftUI

struct EditorToolButton: View {
    let preset: DrawingToolPreset
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            content
            .animation(.easeOut(duration: 0.16), value: isSelected)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    @ViewBuilder
    private var content: some View {
        switch preset.kind {
        case .fountainPen:
            FountainPenToolObjectView(
                inkColor: Color(uiColor: EditorToolFactory.color(for: preset)),
                isSelected: isSelected
            )
        case .pen:
            PenToolObjectView(
                inkColor: Color(uiColor: EditorToolFactory.color(for: preset)),
                isSelected: isSelected
            )
        case .pencil:
            PencilToolObjectView(
                bodyColor: Color(uiColor: EditorToolFactory.color(for: preset)),
                isSelected: isSelected
            )
        case .marker:
            MarkerToolObjectView(
                bodyColor: Color(uiColor: EditorToolFactory.color(for: preset)),
                isSelected: isSelected
            )
        case .eraser:
            EraserToolObjectView(isSelected: isSelected)
        case .lasso:
            LassoToolObjectView(isSelected: isSelected)
        }
    }

    private var accessibilityLabel: String {
        "\(preset.name), \(EditorDrawingTool(kind: preset.kind).title)"
    }

    private var accessibilityHint: String {
        if isSelected, preset.kind.isWritingTool {
            return "Tocca di nuovo per aprire le impostazioni."
        }

        return "Seleziona lo strumento."
    }
}

struct AddToolPresetButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.045))
                    .frame(width: 36, height: 36)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
                    }

                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("Aggiungi strumento")
        .accessibilityHint("Crea una nuova penna personalizzata.")
    }
}
