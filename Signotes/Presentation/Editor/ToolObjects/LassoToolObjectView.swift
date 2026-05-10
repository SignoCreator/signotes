import SwiftUI

struct LassoToolObjectView: View {
    let isSelected: Bool

    var body: some View {
        EditorToolObjectChrome(isSelected: isSelected) {
            LassoIconGlyph()
        }
    }
}

private struct LassoIconGlyph: View {
    private let outlineWidth: CGFloat = 2.2

    var body: some View {
        ZStack {
            loop
            knot
            tail
        }
        .frame(width: 36, height: 36)
    }

    private var loop: some View {
        loopPath
            .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineCap: .round, lineJoin: .round, dash: [3.4, 3.0]))
    }

    private var loopPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 9.6, y: 17.2))
            path.addCurve(
                to: CGPoint(x: 23.5, y: 10.0),
                control1: CGPoint(x: 9.2, y: 9.8),
                control2: CGPoint(x: 18.0, y: 6.4)
            )
            path.addCurve(
                to: CGPoint(x: 28.2, y: 18.4),
                control1: CGPoint(x: 27.2, y: 12.4),
                control2: CGPoint(x: 29.3, y: 16.0)
            )
            path.addCurve(
                to: CGPoint(x: 16.4, y: 23.4),
                control1: CGPoint(x: 26.4, y: 23.0),
                control2: CGPoint(x: 19.6, y: 25.1)
            )
            path.addCurve(
                to: CGPoint(x: 9.6, y: 17.2),
                control1: CGPoint(x: 12.8, y: 21.5),
                control2: CGPoint(x: 9.8, y: 20.1)
            )
        }
    }

    private var knot: some View {
        Circle()
            .fill(Color(uiColor: .systemBackground))
            .frame(width: 5.2, height: 5.2)
            .overlay {
                Circle()
                    .stroke(outlineColor, lineWidth: 1.6)
            }
            .position(x: 18.0, y: 23.0)
    }

    private var tail: some View {
        Path { path in
            path.move(to: CGPoint(x: 18.5, y: 24.8))
            path.addCurve(
                to: CGPoint(x: 27.6, y: 31.6),
                control1: CGPoint(x: 21.4, y: 25.8),
                control2: CGPoint(x: 25.8, y: 27.2)
            )
            path.move(to: CGPoint(x: 25.3, y: 27.8))
            path.addLine(to: CGPoint(x: 29.4, y: 27.6))
        }
        .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineCap: .round, lineJoin: .round, dash: [3.2, 2.8]))
    }

    private var outlineColor: Color {
        Color(red: 0.90, green: 0.91, blue: 0.92)
    }
}
