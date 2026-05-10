import SwiftUI

struct PenToolObjectView: View {
    let inkColor: Color
    let isSelected: Bool

    var body: some View {
        EditorToolObjectChrome(isSelected: isSelected) {
            PenIconGlyph(inkColor: inkColor)
        }
    }
}

private struct PenIconGlyph: View {
    let inkColor: Color
    private let outlineWidth: CGFloat = 2.1

    var body: some View {
        ZStack {
            barrel
            metalTip
            bodyDetail
            writingPoint
        }
        .frame(width: 36, height: 36)
    }

    private var barrel: some View {
        barrelPath
            .fill(inkColor)
            .overlay {
                barrelPath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var barrelPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 13.4, y: 14.6))
            path.addLine(to: CGPoint(x: 22.6, y: 14.6))
            path.addCurve(
                to: CGPoint(x: 23.8, y: 32.8),
                control1: CGPoint(x: 23.1, y: 20.0),
                control2: CGPoint(x: 23.6, y: 27.6)
            )
            path.addQuadCurve(to: CGPoint(x: 20.8, y: 35.0), control: CGPoint(x: 23.8, y: 34.3))
            path.addLine(to: CGPoint(x: 15.2, y: 35.0))
            path.addQuadCurve(to: CGPoint(x: 12.2, y: 32.8), control: CGPoint(x: 12.2, y: 34.3))
            path.addCurve(
                to: CGPoint(x: 13.4, y: 14.6),
                control1: CGPoint(x: 12.4, y: 27.6),
                control2: CGPoint(x: 12.9, y: 20.0)
            )
            path.closeSubpath()
        }
    }

    private var metalTip: some View {
        Path { path in
            path.move(to: CGPoint(x: 18.0, y: 4.8))
            path.addQuadCurve(to: CGPoint(x: 22.6, y: 14.6), control: CGPoint(x: 21.6, y: 8.2))
            path.addLine(to: CGPoint(x: 13.4, y: 14.6))
            path.addQuadCurve(to: CGPoint(x: 18.0, y: 4.8), control: CGPoint(x: 14.4, y: 8.2))
            path.closeSubpath()
        }
        .fill(metalFill)
        .overlay {
            Path { path in
                path.move(to: CGPoint(x: 18.0, y: 4.8))
                path.addQuadCurve(to: CGPoint(x: 22.6, y: 14.6), control: CGPoint(x: 21.6, y: 8.2))
                path.addLine(to: CGPoint(x: 13.4, y: 14.6))
                path.addQuadCurve(to: CGPoint(x: 18.0, y: 4.8), control: CGPoint(x: 14.4, y: 8.2))
                path.closeSubpath()
            }
            .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
        }
    }

    private var bodyDetail: some View {
        Path { path in
            path.move(to: CGPoint(x: 20.7, y: 18.0))
            path.addLine(to: CGPoint(x: 20.7, y: 28.2))
        }
        .stroke(outlineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }

    private var writingPoint: some View {
        Circle()
            .fill(outlineColor)
            .frame(width: 2.8, height: 2.8)
            .position(x: 18.0, y: 4.0)
    }

    private var outlineColor: Color {
        .black
    }

    private var metalFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(white: 0.95),
                Color(white: 0.72)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
