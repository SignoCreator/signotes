enum PageTemplate: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case blank
    case ruled
    case grid
    case dotted

    var id: String { rawValue }
}

