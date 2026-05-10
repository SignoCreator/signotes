import SwiftUI

struct ToolKindObjectPreview: View {
    let kind: DrawingToolKind
    let colorHex: String
    let scale: CGFloat

    var body: some View {
        preview
            .scaleEffect(scale)
            .frame(width: 50, height: 50)
            .clipped()
    }

    @ViewBuilder
    private var preview: some View {
        switch kind {
        case .fountainPen:
            FountainPenToolObjectView(inkColor: color, isSelected: false)
        case .pen:
            PenToolObjectView(inkColor: color, isSelected: false)
        case .pencil:
            PencilToolObjectView(bodyColor: color, isSelected: false)
        case .marker:
            MarkerToolObjectView(bodyColor: color, isSelected: false)
        case .eraser:
            EraserToolObjectView(isSelected: false)
        case .lasso:
            LassoToolObjectView(isSelected: false)
        }
    }

    private var color: Color {
        Color(uiColor: UIColor(hex: colorHex) ?? .black)
    }
}
