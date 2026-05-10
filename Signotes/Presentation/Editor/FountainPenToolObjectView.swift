import SwiftUI

struct FountainPenToolObjectView: View {
    let inkColor: Color
    let isSelected: Bool

    var body: some View {
        EditorToolObjectChrome(isSelected: isSelected) {
            FountainPenIconGlyph(inkColor: inkColor)
        }
    }
}

private struct FountainPenIconGlyph: View {
    let inkColor: Color
    private let outlineWidth: CGFloat = 2

    var body: some View {
        ZStack {
            barrel
            nibShape
            nibSlit
            nibDot
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
            path.move(to: CGPoint(x: 14.0, y: 18.0))
            path.addLine(to: CGPoint(x: 22.0, y: 18.0))
            path.addCurve(
                to: CGPoint(x: 24.6, y: 32.6),
                control1: CGPoint(x: 23.1, y: 21.2),
                control2: CGPoint(x: 24.3, y: 27.8)
            )
            path.addQuadCurve(to: CGPoint(x: 21.4, y: 35.0), control: CGPoint(x: 24.5, y: 34.2))
            path.addLine(to: CGPoint(x: 14.6, y: 35.0))
            path.addQuadCurve(to: CGPoint(x: 11.4, y: 32.6), control: CGPoint(x: 11.5, y: 34.2))
            path.addCurve(
                to: CGPoint(x: 14.0, y: 18.0),
                control1: CGPoint(x: 11.7, y: 27.8),
                control2: CGPoint(x: 12.9, y: 21.2)
            )
            path.closeSubpath()
        }
    }

    private var nibShape: some View {
        Path { path in
            path.move(to: CGPoint(x: 18.0, y: 3.3))
            path.addQuadCurve(to: CGPoint(x: 24.8, y: 12.1), control: CGPoint(x: 23.5, y: 6.6))
            path.addLine(to: CGPoint(x: 21.0, y: 18.0))
            path.addLine(to: CGPoint(x: 15.0, y: 18.0))
            path.addLine(to: CGPoint(x: 11.2, y: 12.1))
            path.addQuadCurve(to: CGPoint(x: 18.0, y: 3.3), control: CGPoint(x: 12.5, y: 6.6))
            path.closeSubpath()
        }
        .fill(.white)
        .overlay {
            Path { path in
                path.move(to: CGPoint(x: 18.0, y: 3.3))
                path.addQuadCurve(to: CGPoint(x: 24.8, y: 12.1), control: CGPoint(x: 23.5, y: 6.6))
                path.addLine(to: CGPoint(x: 21.0, y: 18.0))
                path.addLine(to: CGPoint(x: 15.0, y: 18.0))
                path.addLine(to: CGPoint(x: 11.2, y: 12.1))
                path.addQuadCurve(to: CGPoint(x: 18.0, y: 3.3), control: CGPoint(x: 12.5, y: 6.6))
                path.closeSubpath()
            }
            .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
        }
    }

    private var nibSlit: some View {
        Path { path in
            path.move(to: CGPoint(x: 18.0, y: 3.7))
            path.addLine(to: CGPoint(x: 18.0, y: 12.0))
        }
        .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineCap: .round))
    }

    private var nibDot: some View {
        Circle()
            .fill(inkColor)
            .frame(width: 4, height: 4)
            .overlay {
                Circle()
                    .stroke(outlineColor, lineWidth: 1)
            }
            .position(x: 18.0, y: 12.1)
    }

    private var outlineColor: Color {
        .black
    }
}
