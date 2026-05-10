import SwiftUI

struct EraserToolObjectView: View {
    let isSelected: Bool

    var body: some View {
        EditorToolObjectChrome(isSelected: isSelected) {
            EraserIconGlyph()
        }
    }
}

private struct EraserIconGlyph: View {
    private let outlineWidth: CGFloat = 2.1

    var body: some View {
        ZStack {
            sleeve
            eraserBody
            bevel
            frontFacet
        }
        .frame(width: 36, height: 36)
    }

    private var sleeve: some View {
        sleevePath
            .fill(sleeveFill)
            .overlay {
                sleevePath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var sleevePath: Path {
        Path { path in
            path.move(to: CGPoint(x: 12.2, y: 18.6))
            path.addLine(to: CGPoint(x: 23.8, y: 18.6))
            path.addLine(to: CGPoint(x: 25.0, y: 32.4))
            path.addQuadCurve(to: CGPoint(x: 21.9, y: 35.0), control: CGPoint(x: 25.0, y: 34.0))
            path.addLine(to: CGPoint(x: 14.1, y: 35.0))
            path.addQuadCurve(to: CGPoint(x: 11.0, y: 32.4), control: CGPoint(x: 11.0, y: 34.0))
            path.addLine(to: CGPoint(x: 12.2, y: 18.6))
            path.closeSubpath()
        }
    }

    private var eraserBody: some View {
        eraserPath
            .fill(eraserFill)
            .overlay {
                eraserPath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var eraserPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 13.0, y: 7.2))
            path.addQuadCurve(to: CGPoint(x: 15.4, y: 4.8), control: CGPoint(x: 13.0, y: 5.8))
            path.addLine(to: CGPoint(x: 20.6, y: 4.8))
            path.addQuadCurve(to: CGPoint(x: 23.0, y: 7.2), control: CGPoint(x: 23.0, y: 5.8))
            path.addLine(to: CGPoint(x: 23.8, y: 18.6))
            path.addLine(to: CGPoint(x: 12.2, y: 18.6))
            path.closeSubpath()
        }
    }

    private var bevel: some View {
        Path { path in
            path.move(to: CGPoint(x: 14.8, y: 8.6))
            path.addLine(to: CGPoint(x: 21.2, y: 8.6))
        }
        .stroke(outlineColor.opacity(0.55), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
    }

    private var frontFacet: some View {
        Path { path in
            path.move(to: CGPoint(x: 14.0, y: 25.2))
            path.addLine(to: CGPoint(x: 22.0, y: 25.2))
        }
        .stroke(outlineColor.opacity(0.58), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private var outlineColor: Color {
        .black
    }

    private var eraserFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.74, blue: 0.78),
                Color(red: 0.95, green: 0.42, blue: 0.50)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var sleeveFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(white: 0.96),
                Color(white: 0.70)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
