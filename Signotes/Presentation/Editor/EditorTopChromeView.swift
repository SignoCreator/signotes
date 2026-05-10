import SwiftUI

struct EditorTopChromeView: View {
    let title: String
    let pageIndicatorText: String
    @Binding var selectedTemplate: PageTemplate
    let onBack: () -> Void
    let onResetZoom: () -> Void
    let onUndo: () -> Void
    let onRedo: () -> Void
    let commandAvailability: EditorCanvasCommandAvailability
    @Binding var toolState: EditorToolState
    let onCreatePreset: (String, DrawingToolKind, String, Double) async -> Void
    let onUpdatePreset: (UUID, String, DrawingToolKind, String, Double) async -> Void
    let onDeletePreset: (UUID) async -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Indietro")

                Text(title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(pageIndicatorText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityLabel("Pagina \(pageIndicatorText)")

                Button(action: onResetZoom) {
                    Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Adatta larghezza")
            }
            .padding(.horizontal, 12)
            .frame(height: 44)

            EditorToolPaletteView(
                selectedTemplate: $selectedTemplate,
                onUndo: onUndo,
                onRedo: onRedo,
                commandAvailability: commandAvailability,
                toolState: $toolState,
                onCreatePreset: onCreatePreset,
                onUpdatePreset: onUpdatePreset,
                onDeletePreset: onDeletePreset
            )
        }
        .foregroundStyle(.primary)
        .background(.regularMaterial)
        .background(chromeFill)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.11))
                .frame(height: 1)
        }
    }

    private var chromeFill: Color {
        colorScheme == .dark
            ? Color(uiColor: .secondarySystemBackground).opacity(0.82)
            : Color(uiColor: .systemBackground).opacity(0.90)
    }
}

extension PageTemplate {
    var displayName: String {
        switch self {
        case .blank:
            "Bianco"
        case .ruled:
            "Righe"
        case .grid:
            "Quadretti"
        case .dotted:
            "Puntinato"
        }
    }

    var systemImageName: String {
        switch self {
        case .blank:
            "doc"
        case .ruled:
            "list.bullet"
        case .grid:
            "square.grid.3x3"
        case .dotted:
            "circle.grid.3x3"
        }
    }
}
