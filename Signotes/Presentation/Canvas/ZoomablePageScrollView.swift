import SwiftUI
import UIKit

struct ZoomablePageScrollView<Content: View>: UIViewRepresentable {
    let pageSize: CGSize
    @Binding var zoomScale: CGFloat
    let resetZoomToken: Int
    let content: Content

    init(
        pageSize: CGSize,
        zoomScale: Binding<CGFloat>,
        resetZoomToken: Int,
        @ViewBuilder content: () -> Content
    ) {
        self.pageSize = pageSize
        self._zoomScale = zoomScale
        self.resetZoomToken = resetZoomToken
        self.content = content()
    }

    func makeUIView(context: Context) -> PageZoomScrollView {
        let scrollView = PageZoomScrollView()
        scrollView.backgroundColor = .clear
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.keyboardDismissMode = .interactive

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hostingController.view)
        context.coordinator.hostingController = hostingController
        context.coordinator.hostedView = hostingController.view
        context.coordinator.widthConstraint = hostingController.view.widthAnchor.constraint(equalToConstant: pageSize.width)
        context.coordinator.heightConstraint = hostingController.view.heightAnchor.constraint(equalToConstant: pageSize.height)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            context.coordinator.widthConstraint,
            context.coordinator.heightConstraint
        ].compactMap { $0 })

        scrollView.onLayout = { [weak coordinator = context.coordinator, weak scrollView] in
            guard let coordinator, let scrollView else {
                return
            }

            coordinator.configureZoomIfNeeded(in: scrollView, pageSize: pageSize, resetZoomToken: resetZoomToken)
        }

        return scrollView
    }

    func updateUIView(_ scrollView: PageZoomScrollView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.hostingController?.rootView = content
        context.coordinator.widthConstraint?.constant = pageSize.width
        context.coordinator.heightConstraint?.constant = pageSize.height
        context.coordinator.configureZoomIfNeeded(in: scrollView, pageSize: pageSize, resetZoomToken: resetZoomToken)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomablePageScrollView
        var hostingController: UIHostingController<Content>?
        weak var hostedView: UIView?
        var widthConstraint: NSLayoutConstraint?
        var heightConstraint: NSLayoutConstraint?
        private var lastBoundsSize: CGSize = .zero
        private var lastResetZoomToken = 0
        private var hasConfiguredInitialZoom = false

        init(parent: ZoomablePageScrollView) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostedView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            centerContent(in: scrollView)
            parent.zoomScale = scrollView.zoomScale
        }

        func configureZoomIfNeeded(in scrollView: UIScrollView, pageSize: CGSize, resetZoomToken: Int) {
            guard scrollView.bounds.size.width > 0, scrollView.bounds.size.height > 0 else {
                return
            }

            let configuration = CanvasViewportConfiguration(pageSize: pageSize, viewportSize: scrollView.bounds.size)
            scrollView.minimumZoomScale = configuration.minimumZoomScale
            scrollView.maximumZoomScale = configuration.maximumZoomScale

            let boundsChanged = lastBoundsSize != scrollView.bounds.size
            let resetRequested = lastResetZoomToken != resetZoomToken

            if !hasConfiguredInitialZoom || boundsChanged || resetRequested {
                scrollView.setZoomScale(configuration.minimumZoomScale, animated: resetRequested)
                parent.zoomScale = configuration.minimumZoomScale
                lastBoundsSize = scrollView.bounds.size
                lastResetZoomToken = resetZoomToken
                hasConfiguredInitialZoom = true
            } else {
                let clampedZoomScale = configuration.clampedZoomScale(scrollView.zoomScale)
                if clampedZoomScale != scrollView.zoomScale {
                    scrollView.setZoomScale(clampedZoomScale, animated: false)
                }
            }

            centerContent(in: scrollView)
        }

        private func centerContent(in scrollView: UIScrollView) {
            let contentWidth = scrollView.contentSize.width
            let contentHeight = scrollView.contentSize.height
            let horizontalInset = max((scrollView.bounds.width - contentWidth) / 2, 0)
            let verticalInset = max((scrollView.bounds.height - contentHeight) / 2, 0)
            scrollView.contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }
    }
}

final class PageZoomScrollView: UIScrollView {
    var onLayout: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }
}
