enum DrawingToolKind: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case fountainPen
    case pen
    case pencil
    case marker
    case eraser
    case lasso

    var id: String { rawValue }
}

