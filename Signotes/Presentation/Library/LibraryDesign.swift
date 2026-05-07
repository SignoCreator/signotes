import SwiftUI

enum LibraryColorPalette {
    static let folderDefault = "#F2C94C"
    static let noteDefault = "#4F8BFF"

    static let colors = [
        "#F2C94C",
        "#4F8BFF",
        "#5AC8A8",
        "#FF7A59",
        "#AF7AFF",
        "#8E8E93"
    ]
}

extension Color {
    init?(hex: String?) {
        guard let hex else {
            return nil
        }

        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}

struct LibraryTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        configuration.isPressed
                            ? Color.accentColor.opacity(0.14)
                            : Color(uiColor: .secondarySystemGroupedBackground).opacity(0.001)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        configuration.isPressed
                            ? Color.accentColor.opacity(0.24)
                            : Color.clear,
                        lineWidth: 1
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.16), value: configuration.isPressed)
    }
}
