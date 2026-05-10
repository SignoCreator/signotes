import SwiftUI

struct ToolPresetSettingsHeader: View {
    @Binding var name: String
    let kind: DrawingToolKind
    let colorHex: String
    var isNameFocused: FocusState<Bool>.Binding

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ToolKindObjectPreview(kind: kind, colorHex: colorHex, scale: 1.08)
                .frame(width: 70, height: 70)
                .background(iconFill, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 6) {
                TextField("Nome strumento", text: $name)
                    .font(.title3.weight(.semibold))
                    .textFieldStyle(.plain)
                    .lineLimit(1)
                    .focused(isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFocused.wrappedValue = false
                    }

                Text(EditorDrawingTool(kind: kind).title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var iconFill: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.055)
    }
}
