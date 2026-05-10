enum EditorDrawingTool: String, CaseIterable, Identifiable, Equatable, Hashable {
    case fountainPen
    case pen
    case pencil
    case marker
    case eraser
    case lasso

    var id: String { rawValue }

    init(kind: DrawingToolKind) {
        switch kind {
        case .fountainPen:
            self = .fountainPen
        case .pen:
            self = .pen
        case .pencil:
            self = .pencil
        case .marker:
            self = .marker
        case .eraser:
            self = .eraser
        case .lasso:
            self = .lasso
        }
    }

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

    var kind: DrawingToolKind {
        switch self {
        case .fountainPen:
            .fountainPen
        case .pen:
            .pen
        case .pencil:
            .pencil
        case .marker:
            .marker
        case .eraser:
            .eraser
        case .lasso:
            .lasso
        }
    }

    var preset: DrawingToolPreset {
        DrawingToolPreset.defaults.first { $0.kind == kind } ?? DrawingToolPreset.defaultFountainPen
    }
}
