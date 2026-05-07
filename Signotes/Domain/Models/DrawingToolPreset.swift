import Foundation

struct DrawingToolPreset: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var kind: DrawingToolKind
    var colorHex: String
    var width: Double

    init(
        id: UUID = UUID(),
        name: String,
        kind: DrawingToolKind,
        colorHex: String = "#000000",
        width: Double = 2.4
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.colorHex = colorHex
        self.width = width
    }
}

extension DrawingToolPreset {
    static let defaults: [DrawingToolPreset] = [
        DrawingToolPreset(
            id: UUID(uuidString: "F8320957-0D3E-4DF8-A01B-93B069B4E2C9")!,
            name: "Fountain Pen",
            kind: .fountainPen,
            width: 2.4
        ),
        DrawingToolPreset(
            id: UUID(uuidString: "93E93495-D7FB-4E5F-9CB0-BE11CCCF6E64")!,
            name: "Pen",
            kind: .pen,
            width: 2.0
        ),
        DrawingToolPreset(
            id: UUID(uuidString: "6AA1B4DF-E31B-4C46-AC37-1534A29CB2ED")!,
            name: "Pencil",
            kind: .pencil,
            colorHex: "#3A3A3A",
            width: 3.0
        ),
        DrawingToolPreset(
            id: UUID(uuidString: "A65047C3-9C0B-423D-B9C5-E5FBF8B76AA5")!,
            name: "Marker",
            kind: .marker,
            colorHex: "#FFE66D",
            width: 8.0
        ),
        DrawingToolPreset(
            id: UUID(uuidString: "2C6E7FE8-FC0E-4445-BE7D-8E55651647AA")!,
            name: "Eraser",
            kind: .eraser,
            width: 8.0
        ),
        DrawingToolPreset(
            id: UUID(uuidString: "0C2817F4-036D-4B57-B02D-A3D551632A28")!,
            name: "Lasso",
            kind: .lasso,
            width: 1.0
        )
    ]
}

