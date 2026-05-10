import CoreGraphics

struct CanvasViewportConfiguration: Equatable {
    let pageSize: CGSize
    let viewportSize: CGSize
    let horizontalPadding: CGFloat
    let maxZoomScale: CGFloat

    init(
        pageSize: CGSize,
        viewportSize: CGSize,
        horizontalPadding: CGFloat = 160,
        maxZoomScale: CGFloat = 8
    ) {
        self.pageSize = pageSize
        self.viewportSize = viewportSize
        self.horizontalPadding = horizontalPadding
        self.maxZoomScale = maxZoomScale
    }

    var fitToWidthScale: CGFloat {
        guard pageSize.width > 0, viewportSize.width > horizontalPadding else {
            return 1
        }

        return (viewportSize.width - horizontalPadding) / pageSize.width
    }

    var minimumZoomScale: CGFloat {
        max(0.1, fitToWidthScale)
    }

    var maximumZoomScale: CGFloat {
        max(maxZoomScale, minimumZoomScale)
    }

    func clampedZoomScale(_ zoomScale: CGFloat) -> CGFloat {
        min(max(zoomScale, minimumZoomScale), maximumZoomScale)
    }
}
