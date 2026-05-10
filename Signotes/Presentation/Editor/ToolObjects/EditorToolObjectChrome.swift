import SwiftUI

struct EditorToolObjectChrome<Glyph: View>: View {
    let isSelected: Bool
    private let glyph: Glyph
    @Environment(\.colorScheme) private var colorScheme

    init(isSelected: Bool, @ViewBuilder glyph: () -> Glyph) {
        self.isSelected = isSelected
        self.glyph = glyph()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(selectionFill)
                .frame(width: 41, height: 41)
                .overlay {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(selectionStroke, lineWidth: isSelected ? 2 : 1)
                }
                .opacity(isSelected ? 1 : 0)
                .offset(y: isSelected ? -1 : 3)

            glyph
                .frame(width: 36, height: 36)
                .offset(y: isSelected ? -4 : 3)
                .shadow(color: .black.opacity(isSelected ? 0.22 : 0.10), radius: isSelected ? 8 : 3, x: 0, y: isSelected ? 5 : 2)
        }
        .frame(width: 44, height: 62, alignment: .bottom)
        .animation(.spring(response: 0.24, dampingFraction: 0.82), value: isSelected)
    }

    private var selectionFill: Color {
        Color.accentColor.opacity(colorScheme == .dark ? 0.26 : 0.18)
    }

    private var selectionStroke: Color {
        isSelected
            ? Color.accentColor.opacity(0.86)
            : Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08)
    }
}
