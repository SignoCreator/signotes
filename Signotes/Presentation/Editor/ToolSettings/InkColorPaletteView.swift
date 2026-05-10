import SwiftUI

struct InkColorPaletteView: View {
    @Binding var colorHex: String

    private let palette = [
        "#000000",
        "#3A3A3A",
        "#FFFFFF",
        "#FF3B30",
        "#FF9500",
        "#FFCC00",
        "#34C759",
        "#007AFF",
        "#5856D6",
        "#AF52DE",
        "#FF2D55"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colore")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(palette, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(uiColor: UIColor(hex: hex) ?? .black))
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle()
                                    .stroke(colorHex == hex ? Color.accentColor : Color.primary.opacity(0.18), lineWidth: colorHex == hex ? 3 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Colore \(hex)")
                }

                ColorPicker(
                    "",
                    selection: Binding(
                        get: {
                            Color(uiColor: UIColor(hex: colorHex) ?? .black)
                        },
                        set: { color in
                            colorHex = UIColor(color).hexRGB ?? colorHex
                        }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
                .frame(width: 30, height: 30)
                .accessibilityLabel("Colore personalizzato")
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(28), spacing: 8), count: 6)
    }
}

private extension UIColor {
    var hexRGB: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
