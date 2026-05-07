import SwiftUI

struct EditorToolPaletteView: View {
    @Binding var selectedTool: EditorDrawingTool

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EditorDrawingTool.allCases) { tool in
                Button {
                    selectedTool = tool
                } label: {
                    Image(systemName: tool.systemImageName)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 42, height: 38)
                        .foregroundStyle(selectedTool == tool ? .white : .primary)
                        .overlay(alignment: .bottomTrailing) {
                            if let swatchColor = tool.swatchColor {
                                Circle()
                                    .fill(Color(uiColor: swatchColor))
                                    .frame(width: 9, height: 9)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.85), lineWidth: 1)
                                    )
                                    .offset(x: -6, y: -5)
                            }
                        }
                }
                .buttonStyle(.plain)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selectedTool == tool ? Color.accentColor : Color(uiColor: .secondarySystemGroupedBackground))
                }
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityLabel(tool.title)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}
