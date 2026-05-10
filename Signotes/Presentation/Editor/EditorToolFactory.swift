import PencilKit
import UIKit

enum EditorToolFactory {
    static func makeTool(for preset: DrawingToolPreset) -> any PKTool {
        switch preset.kind {
        case .fountainPen:
            return PKInkingTool(.fountainPen, color: color(for: preset), width: CGFloat(preset.width))
        case .pen:
            return PKInkingTool(.pen, color: color(for: preset), width: CGFloat(preset.width))
        case .pencil:
            return PKInkingTool(.pencil, color: color(for: preset), width: CGFloat(preset.width))
        case .marker:
            return PKInkingTool(
                .marker,
                color: color(for: preset).withAlphaComponent(0.72),
                width: CGFloat(preset.width)
            )
        case .eraser:
            return PKEraserTool(.bitmap)
        case .lasso:
            return PKLassoTool()
        }
    }

    static func color(for preset: DrawingToolPreset) -> UIColor {
        UIColor(hex: preset.colorHex) ?? .black
    }
}

extension UIColor {
    convenience init?(hex: String?) {
        guard let hex else {
            return nil
        }

        let sanitized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard sanitized.count == 6, let value = Int(sanitized, radix: 16) else {
            return nil
        }

        self.init(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
