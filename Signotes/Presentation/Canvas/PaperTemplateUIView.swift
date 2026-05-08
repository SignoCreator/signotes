import UIKit

final class PaperTemplateUIView: UIView {
    var template: PageTemplate = .blank {
        didSet {
            setNeedsDisplay()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        isOpaque = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        isOpaque = true
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        UIColor.white.setFill()
        context.fill(rect)

        switch template {
        case .blank:
            break
        case .ruled:
            drawRuled(in: context, rect: rect)
        case .grid:
            drawGrid(in: context, rect: rect)
        case .dotted:
            drawDotted(in: context, rect: rect)
        }
    }

    private func drawRuled(in context: CGContext, rect: CGRect) {
        context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.18).cgColor)
        context.setLineWidth(1)

        let spacing: CGFloat = 32
        var y = spacing
        while y < rect.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }

        context.strokePath()
    }

    private func drawGrid(in context: CGContext, rect: CGRect) {
        context.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.12).cgColor)
        context.setLineWidth(1)

        let spacing: CGFloat = 24
        var position = spacing
        while position < rect.width {
            context.move(to: CGPoint(x: position, y: 0))
            context.addLine(to: CGPoint(x: position, y: rect.height))
            position += spacing
        }

        position = spacing
        while position < rect.height {
            context.move(to: CGPoint(x: 0, y: position))
            context.addLine(to: CGPoint(x: rect.width, y: position))
            position += spacing
        }

        context.strokePath()
    }

    private func drawDotted(in context: CGContext, rect: CGRect) {
        context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.16).cgColor)

        let spacing: CGFloat = 24
        let radius: CGFloat = 1.2
        var x = spacing

        while x < rect.width {
            var y = spacing

            while y < rect.height {
                context.fillEllipse(
                    in: CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                )
                y += spacing
            }

            x += spacing
        }
    }
}
