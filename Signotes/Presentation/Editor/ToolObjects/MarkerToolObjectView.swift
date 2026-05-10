import SwiftUI

struct MarkerToolObjectView: View {
    let bodyColor: Color
    let isSelected: Bool

    var body: some View {
        EditorToolObjectChrome(isSelected: isSelected) {
            MarkerIconGlyph(bodyColor: bodyColor)
        }
    }
}

private struct MarkerIconGlyph: View {
    let bodyColor: Color
    private let outlineWidth: CGFloat = 2.1

    var body: some View {
        ZStack {
            barrel
            neck
            chiselTip
            capLine
        }
        .frame(width: 36, height: 36)
    }

    private var barrel: some View {
        barrelPath
            .fill(bodyColor)
            .overlay {
                barrelPath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var barrelPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 11.4, y: 18.0))
            path.addLine(to: CGPoint(x: 24.6, y: 18.0))
            path.addLine(to: CGPoint(x: 25.8, y: 32.2))
            path.addQuadCurve(to: CGPoint(x: 22.6, y: 35.0), control: CGPoint(x: 25.8, y: 34.0))
            path.addLine(to: CGPoint(x: 13.4, y: 35.0))
            path.addQuadCurve(to: CGPoint(x: 10.2, y: 32.2), control: CGPoint(x: 10.2, y: 34.0))
            path.addLine(to: CGPoint(x: 11.4, y: 18.0))
            path.closeSubpath()
        }
    }

    private var neck: some View {
        neckPath
            .fill(.white)
            .overlay {
                neckPath
                    .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
            }
    }

    private var neckPath: Path {
        Path { path in
            path.move(to: CGPoint(x: 14.3, y: 12.2))
            path.addLine(to: CGPoint(x: 21.7, y: 12.2))
            path.addLine(to: CGPoint(x: 24.6, y: 18.0))
            path.addLine(to: CGPoint(x: 11.4, y: 18.0))
            path.closeSubpath()
        }
    }

    private var chiselTip: some View {
        Path { path in
            path.move(to: CGPoint(x: 15.2, y: 4.0))
            path.addLine(to: CGPoint(x: 22.7, y: 7.5))
            path.addLine(to: CGPoint(x: 21.7, y: 12.2))
            path.addLine(to: CGPoint(x: 14.3, y: 12.2))
            path.addLine(to: CGPoint(x: 13.4, y: 7.5))
            path.closeSubpath()
        }
        .fill(tipFill)
        .overlay {
            Path { path in
                path.move(to: CGPoint(x: 15.2, y: 4.0))
                path.addLine(to: CGPoint(x: 22.7, y: 7.5))
                path.addLine(to: CGPoint(x: 21.7, y: 12.2))
                path.addLine(to: CGPoint(x: 14.3, y: 12.2))
                path.addLine(to: CGPoint(x: 13.4, y: 7.5))
                path.closeSubpath()
            }
            .stroke(outlineColor, style: StrokeStyle(lineWidth: outlineWidth, lineJoin: .round))
        }
    }

    private var capLine: some View {
        Path { path in
            path.move(to: CGPoint(x: 14.2, y: 24.0))
            path.addLine(to: CGPoint(x: 21.8, y: 24.0))
        }
        .stroke(outlineColor.opacity(0.62), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }

    private var outlineColor: Color {
        .black
    }

    private var tipFill: Color {
        bodyColor.opacity(0.82)
    }
}
