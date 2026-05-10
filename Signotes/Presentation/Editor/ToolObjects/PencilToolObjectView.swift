import SwiftUI

struct PencilToolObjectView: View {
    let bodyColor: Color
    let isSelected: Bool

    var body: some View {
        EditorToolObjectChrome(isSelected: isSelected) {
            PencilIconGlyph(bodyColor: bodyColor)
        }
    }
}

private struct PencilIconGlyph: View {
    let bodyColor: Color
    private let outlineWidth: CGFloat = 2.1

    var body: some View {
        ZStack {
            barrel
            woodTip
            graphiteTip
            centerFacet
        }
        .frame(width: 36, height: 36)
    }

    private var barrel: some View {
        bodyPath
            .fill(bodyColor)
            .overlay {
                bodyPath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var bodyPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 13.0, y: 14.8))
            path.addLine(to: CGPoint(x: 23.0, y: 14.8))
            path.addLine(to: CGPoint(x: 24.0, y: 32.8))
            path.addQuadCurve(to: CGPoint(x: 21.1, y: 35.0), control: CGPoint(x: 24.0, y: 34.2))
            path.addLine(to: CGPoint(x: 14.9, y: 35.0))
            path.addQuadCurve(to: CGPoint(x: 12.0, y: 32.8), control: CGPoint(x: 12.0, y: 34.2))
            path.addLine(to: CGPoint(x: 13.0, y: 14.8))
            path.closeSubpath()
        }
    }

    private var woodTip: some View {
        woodTipPath
            .fill(woodFill)
            .overlay {
                woodTipPath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var woodTipPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 18.0, y: 3.6))
            path.addLine(to: CGPoint(x: 23.0, y: 14.8))
            path.addLine(to: CGPoint(x: 13.0, y: 14.8))
            path.closeSubpath()
        }
    }

    private var graphiteTip: some View {
        Path { path in
            path.move(to: CGPoint(x: 18.0, y: 3.2))
            path.addLine(to: CGPoint(x: 16.5, y: 6.8))
            path.addQuadCurve(to: CGPoint(x: 19.5, y: 6.8), control: CGPoint(x: 18.0, y: 7.8))
            path.closeSubpath()
        }
        .fill(outlineColor)
    }

    private var centerFacet: some View {
        Path { path in
            path.move(to: CGPoint(x: 18.0, y: 16.8))
            path.addLine(to: CGPoint(x: 18.0, y: 31.2))
        }
        .stroke(outlineColor.opacity(0.62), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private var outlineColor: Color {
        .black
    }

    private var woodFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.80, blue: 0.50),
                Color(red: 0.82, green: 0.58, blue: 0.28)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
