import SwiftUI

struct PageBackgroundView: View {
    let template: PageTemplate

    var body: some View {
        Canvas { context, size in
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white)
            )

            switch template {
            case .blank:
                break
            case .ruled:
                drawRuled(context: context, size: size)
            case .grid:
                drawGrid(context: context, size: size)
            case .dotted:
                drawDotted(context: context, size: size)
            }
        }
    }

    private func drawRuled(context: GraphicsContext, size: CGSize) {
        var path = Path()
        let spacing: CGFloat = 32
        var y = spacing

        while y < size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += spacing
        }

        context.stroke(path, with: .color(.blue.opacity(0.18)), lineWidth: 1)
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        var path = Path()
        let spacing: CGFloat = 24
        var position = spacing

        while position < size.width {
            path.move(to: CGPoint(x: position, y: 0))
            path.addLine(to: CGPoint(x: position, y: size.height))
            position += spacing
        }

        position = spacing

        while position < size.height {
            path.move(to: CGPoint(x: 0, y: position))
            path.addLine(to: CGPoint(x: size.width, y: position))
            position += spacing
        }

        context.stroke(path, with: .color(.blue.opacity(0.12)), lineWidth: 1)
    }

    private func drawDotted(context: GraphicsContext, size: CGSize) {
        let spacing: CGFloat = 24
        let radius: CGFloat = 1.2
        var x = spacing

        while x < size.width {
            var y = spacing

            while y < size.height {
                context.fill(
                    Path(
                        ellipseIn: CGRect(
                            x: x - radius,
                            y: y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                    ),
                    with: .color(.blue.opacity(0.16))
                )
                y += spacing
            }

            x += spacing
        }
    }
}

