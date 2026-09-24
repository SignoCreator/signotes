import SwiftUI

struct ToolKindSelectionGrid: View {
    @Binding var selection: DrawingToolKind
    let colorHex: String

    private let columns = [
        GridItem(.fixed(82), spacing: 9),
        GridItem(.fixed(82), spacing: 9),
        GridItem(.fixed(82), spacing: 9),
        GridItem(.fixed(82), spacing: 9)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, alignment: .leading, spacing: 9) {
                ForEach(writingKinds) { kind in
                    Button {
                        selection = kind
                    } label: {
                        VStack(spacing: 7) {
                            ToolKindObjectPreview(kind: kind, colorHex: colorHex, scale: 1.0)
                                .frame(width: 58, height: 52)
                                .scaleEffect(selection == kind ? 1.05 : 1.0)

                            Text(EditorDrawingTool(kind: kind).title)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .frame(width: 82, height: 86)
                        .background(cardFill(isSelected: selection == kind), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(selection == kind ? Color.accentColor : Color.primary.opacity(0.10), lineWidth: selection == kind ? 2 : 1)
                        }
                        .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var writingKinds: [DrawingToolKind] {
        DrawingToolKind.allCases.filter(\.isWritingTool)
    }

    private func cardFill(isSelected: Bool) -> Color {
        isSelected
            ? Color.accentColor.opacity(0.16)
            : Color(uiColor: .secondarySystemBackground)
    }
}
