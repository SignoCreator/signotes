import PencilKit
import UIKit

enum EditorDrawingTool: String, CaseIterable, Identifiable, Equatable, Hashable {
    case fountainPen
    case pen
    case pencil
    case marker
    case eraser
    case lasso

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fountainPen:
            "Stilografica"
        case .pen:
            "Penna"
        case .pencil:
            "Matita"
        case .marker:
            "Evidenziatore"
        case .eraser:
            "Gomma"
        case .lasso:
            "Lazo"
        }
    }

    var systemImageName: String {
        switch self {
        case .fountainPen:
            "pencil.tip"
        case .pen:
            "pencil.line"
        case .pencil:
            "pencil"
        case .marker:
            "highlighter"
        case .eraser:
            "eraser"
        case .lasso:
            "lasso"
        }
    }

    var swatchColor: UIColor? {
        switch self {
        case .fountainPen, .pen:
            UIColor.black
        case .pencil:
            UIColor.darkGray
        case .marker:
            UIColor.systemYellow
        case .eraser, .lasso:
            nil
        }
    }

    func makeTool() -> any PKTool {
        switch self {
        case .fountainPen:
            PKInkingTool(.fountainPen, color: UIColor.black, width: 2.4)
        case .pen:
            PKInkingTool(.pen, color: UIColor.black, width: 2.0)
        case .pencil:
            PKInkingTool(.pencil, color: UIColor.darkGray, width: 3.0)
        case .marker:
            PKInkingTool(.marker, color: UIColor.systemYellow.withAlphaComponent(0.72), width: 8.0)
        case .eraser:
            PKEraserTool(.bitmap)
        case .lasso:
            PKLassoTool()
        }
    }
}
