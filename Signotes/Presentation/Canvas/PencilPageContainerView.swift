import PencilKit
import UIKit

final class PencilPageContainerView: UIView, UIScrollViewDelegate, PKCanvasViewDelegate, UIGestureRecognizerDelegate {
    var onDrawingChange: (@MainActor (PKDrawing) -> Void)?
    var onPageTurn: (@MainActor (PageTurnDirection) -> Void)?
    var onPageTurnDragUpdate: (@MainActor (PageTurnDragUpdate) -> Void)?
    var onCommandAvailabilityChange: (@MainActor (EditorCanvasCommandAvailability) -> Void)?

    private let paperScrollView = UIScrollView()
    private let paperView = PaperTemplateUIView()
    private let canvasView = PKCanvasView()
    private let pageTurnPanGesture = UIPanGestureRecognizer()
    private let pageTurnIntentResolver = PageTurnIntentResolver()
    private var drawingResourceID: String?
    private var pageSize: CGSize = .zero
    private var lastBoundsSize: CGSize = .zero
    private var lastResetZoomToken = 0
    private var hasConfiguredZoom = false
    private var appliedToolPreset: DrawingToolPreset?
    private var isApplyingDrawingProgrammatically = false
    private var appliedRenderingScale: CGFloat = 0
    private var viewportConfiguration: CanvasViewportConfiguration?
    private var pendingDrawingChange: PKDrawing?
    private var drawingChangeWorkItem: DispatchWorkItem?
    private var lastPageTurnDeliveryTime: TimeInterval = 0
    private var activeInteractivePageTurnDirection: PageTurnDirection?
    private var pageTurnAvailability = PageTurnAvailability()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(
        drawingResourceID: String,
        pageSize: CGSize,
        template: PageTemplate,
        initialDrawing: PKDrawing,
        toolPreset: DrawingToolPreset,
        pageTurnAvailability: PageTurnAvailability,
        resetZoomToken: Int
    ) {
        self.pageTurnAvailability = pageTurnAvailability
        updateDrawingIfNeeded(initialDrawing, resourceID: drawingResourceID)
        updatePageSize(pageSize)
        paperView.template = template
        applyToolIfNeeded(toolPreset)
        configureZoomIfNeeded(resetZoomToken: resetZoomToken)
        notifyCommandAvailabilitySoon()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configureZoomIfNeeded(resetZoomToken: lastResetZoomToken)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        scrollView === paperScrollView ? paperView : nil
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === canvasView else {
            return
        }

        syncPaperViewport()
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard scrollView === canvasView else {
            return
        }

        centerPage()
        syncPaperViewport()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard scrollView === canvasView else {
            return
        }

        updateRenderingScale(force: true)
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        guard !isApplyingDrawingProgrammatically else {
            return
        }

        pendingDrawingChange = canvasView.drawing
        scheduleDrawingChangeDelivery()
        notifyCommandAvailabilitySoon()
    }

    func flushPendingDrawingChange() {
        drawingChangeWorkItem?.cancel()
        drawingChangeWorkItem = nil
        deliverPendingDrawingChange()
    }

    func applyCanvasCommand(_ command: EditorCanvasCommand) {
        switch command {
        case .undo:
            canvasView.undoManager?.undo()
        case .redo:
            canvasView.undoManager?.redo()
        }
        notifyCommandAvailabilitySoon()
    }

    private func setup() {
        backgroundColor = .clear

        setupPaperScrollView()
        setupCanvasView()
        setupPageTurnGesture()
    }

    private func setupPaperScrollView() {
        paperScrollView.translatesAutoresizingMaskIntoConstraints = false
        paperScrollView.backgroundColor = .clear
        paperScrollView.delegate = self
        paperScrollView.isUserInteractionEnabled = false
        paperScrollView.showsVerticalScrollIndicator = false
        paperScrollView.showsHorizontalScrollIndicator = false
        paperScrollView.bounces = false
        paperScrollView.bouncesZoom = false
        addSubview(paperScrollView)

        paperView.backgroundColor = .white
        paperView.layer.cornerRadius = 2
        paperView.layer.shadowColor = UIColor.black.cgColor
        paperView.layer.shadowOpacity = 0.16
        paperView.layer.shadowRadius = 18
        paperView.layer.shadowOffset = CGSize(width: 0, height: 8)
        paperScrollView.addSubview(paperView)

        NSLayoutConstraint.activate([
            paperScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            paperScrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            paperScrollView.topAnchor.constraint(equalTo: topAnchor),
            paperScrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupCanvasView() {
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .clear
        canvasView.delegate = self
        canvasView.drawingPolicy = .pencilOnly
        canvasView.isOpaque = false
        canvasView.bounces = true
        // Elastic zoom desynchronizes PencilKit's rendered ink from the mirrored paper background at min/max scale.
        canvasView.bouncesZoom = false
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = false
        canvasView.keyboardDismissMode = .interactive
        canvasView.delaysContentTouches = false
        canvasView.maximumSupportedContentVersion = .version3
        canvasView.overrideUserInterfaceStyle = .light
        addSubview(canvasView)

        NSLayoutConstraint.activate([
            canvasView.leadingAnchor.constraint(equalTo: leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: trailingAnchor),
            canvasView.topAnchor.constraint(equalTo: topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupPageTurnGesture() {
        pageTurnPanGesture.addTarget(self, action: #selector(handlePageTurnPanGesture(_:)))
        pageTurnPanGesture.cancelsTouchesInView = false
        pageTurnPanGesture.delaysTouchesBegan = false
        pageTurnPanGesture.delaysTouchesEnded = false
        pageTurnPanGesture.maximumNumberOfTouches = 1
        pageTurnPanGesture.delegate = self
        addGestureRecognizer(pageTurnPanGesture)
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === pageTurnPanGesture else {
            return true
        }

        let velocity = pageTurnPanGesture.velocity(in: self)
        return abs(velocity.x) > abs(velocity.y) * 1.2
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        gestureRecognizer === pageTurnPanGesture || otherGestureRecognizer === pageTurnPanGesture
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer === pageTurnPanGesture else {
            return true
        }

        return touch.type == .direct
    }

    private func updatePageSize(_ pageSize: CGSize) {
        guard self.pageSize != pageSize else {
            return
        }

        self.pageSize = pageSize
        paperView.frame = CGRect(origin: .zero, size: pageSize)
        paperScrollView.contentSize = pageSize
        canvasView.contentSize = pageSize
        paperView.setNeedsDisplay()
        setNeedsLayout()
    }

    private func updateDrawingIfNeeded(_ drawing: PKDrawing, resourceID: String) {
        guard drawingResourceID != resourceID else {
            return
        }

        drawingResourceID = resourceID
        isApplyingDrawingProgrammatically = true
        canvasView.drawing = drawing
        isApplyingDrawingProgrammatically = false
    }

    private func applyToolIfNeeded(_ toolPreset: DrawingToolPreset) {
        guard appliedToolPreset != toolPreset else {
            return
        }

        canvasView.tool = EditorToolFactory.makeTool(for: toolPreset)
        appliedToolPreset = toolPreset
        canvasView.becomeFirstResponder()
    }

    private func configureZoomIfNeeded(resetZoomToken: Int) {
        guard bounds.width > 0, bounds.height > 0, pageSize.width > 0, pageSize.height > 0 else {
            return
        }

        let configuration = CanvasViewportConfiguration(pageSize: pageSize, viewportSize: bounds.size)
        viewportConfiguration = configuration
        canvasView.minimumZoomScale = configuration.minimumZoomScale
        canvasView.maximumZoomScale = configuration.maximumZoomScale
        paperScrollView.minimumZoomScale = configuration.minimumZoomScale
        paperScrollView.maximumZoomScale = configuration.maximumZoomScale

        let boundsChanged = lastBoundsSize != bounds.size
        let resetRequested = lastResetZoomToken != resetZoomToken

        if !hasConfiguredZoom || resetRequested {
            canvasView.setZoomScale(configuration.minimumZoomScale, animated: resetRequested)
            hasConfiguredZoom = true
        } else if boundsChanged {
            let clampedZoomScale = configuration.clampedZoomScale(canvasView.zoomScale)
            canvasView.setZoomScale(clampedZoomScale, animated: false)
        } else {
            let clampedZoomScale = configuration.clampedZoomScale(canvasView.zoomScale)
            if clampedZoomScale != canvasView.zoomScale {
                canvasView.setZoomScale(clampedZoomScale, animated: false)
            }
        }

        lastBoundsSize = bounds.size
        lastResetZoomToken = resetZoomToken
        updateRenderingScale(force: false)
        centerPage()
        syncPaperViewport()
    }

    private func centerPage() {
        let zoomScale = clampedCanvasZoomScale
        let scaledPageWidth = pageSize.width * zoomScale
        let scaledPageHeight = pageSize.height * zoomScale
        let horizontalInset = max((bounds.width - scaledPageWidth) / 2, 0)
        let verticalInset = max((bounds.height - scaledPageHeight) / 2, 0)
        let inset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )

        canvasView.contentInset = inset
        paperScrollView.contentInset = inset
    }

    private func syncPaperViewport() {
        let zoomScale = clampedCanvasZoomScale
        if paperScrollView.zoomScale != zoomScale {
            paperScrollView.setZoomScale(zoomScale, animated: false)
        }

        paperScrollView.contentOffset = canvasView.contentOffset
    }

    private func updateRenderingScale(force: Bool) {
        let scale = UIScreen.main.scale * max(clampedCanvasZoomScale, 1)
        guard force || abs(scale - appliedRenderingScale) >= 0.5 else {
            return
        }

        appliedRenderingScale = scale
        paperView.contentScaleFactor = scale
        paperView.layer.contentsScale = scale
        paperView.setNeedsDisplay()
    }

    private func scheduleDrawingChangeDelivery() {
        guard drawingChangeWorkItem == nil else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.drawingChangeWorkItem = nil
            self?.deliverPendingDrawingChange()
        }
        drawingChangeWorkItem = workItem
        DispatchQueue.main.async(execute: workItem)
    }

    private func deliverPendingDrawingChange() {
        guard let pendingDrawingChange else {
            return
        }

        self.pendingDrawingChange = nil
        onDrawingChange?(pendingDrawingChange)
    }

    private func notifyCommandAvailabilitySoon() {
        DispatchQueue.main.async { [weak self] in
            self?.deliverCommandAvailability()
        }
    }

    private func deliverCommandAvailability() {
        let undoManager = canvasView.undoManager
        onCommandAvailabilityChange?(
            EditorCanvasCommandAvailability(
                canUndo: undoManager?.canUndo ?? false,
                canRedo: undoManager?.canRedo ?? false
            )
        )
    }

    private var clampedCanvasZoomScale: CGFloat {
        viewportConfiguration?.clampedZoomScale(canvasView.zoomScale) ?? canvasView.zoomScale
    }

    private var isAtBaseZoomScale: Bool {
        guard let viewportConfiguration else {
            return true
        }

        return abs(clampedCanvasZoomScale - viewportConfiguration.minimumZoomScale) < 0.01
    }

    @objc private func handlePageTurnPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self)

        switch gestureRecognizer.state {
        case .began, .changed:
            updateInteractivePageTurn(translation: translation)
        case .ended:
            let deliveredPageTurn = deliverPageTurnIntentIfNeeded(translation: translation)
            if !deliveredPageTurn {
                cancelInteractivePageTurn()
            }
        case .cancelled, .failed:
            cancelInteractivePageTurn()
        default:
            break
        }
    }

    private func updateInteractivePageTurn(translation: CGPoint) {
        if let activeInteractivePageTurnDirection {
            onPageTurnDragUpdate?(
                .changed(
                    direction: activeInteractivePageTurnDirection,
                    translationX: directionalTranslationX(
                        translation.x,
                        for: activeInteractivePageTurnDirection
                    )
                )
            )
            return
        }

        guard let direction = pageTurnIntentResolver.interactiveDirection(
            translation: translation,
            context: pageTurnGestureContext
        ) else {
            return
        }

        beginInteractivePageTurn(direction)
        onPageTurnDragUpdate?(
            .changed(
                direction: direction,
                translationX: directionalTranslationX(translation.x, for: direction)
            )
        )
    }

    private func beginInteractivePageTurn(_ direction: PageTurnDirection) {
        guard activeInteractivePageTurnDirection == nil else {
            return
        }

        activeInteractivePageTurnDirection = direction
    }

    private func cancelInteractivePageTurn() {
        guard activeInteractivePageTurnDirection != nil else {
            return
        }

        activeInteractivePageTurnDirection = nil
        onPageTurnDragUpdate?(.cancelled)
    }

    @discardableResult
    private func deliverPageTurnIntentIfNeeded(translation: CGPoint) -> Bool {
        guard let direction = pageTurnIntentResolver.committedDirection(
            translation: translation,
            activeDirection: activeInteractivePageTurnDirection,
            context: pageTurnGestureContext
        ) else {
            return false
        }

        return deliverPageTurn(direction)
    }

    private var pageTurnGestureContext: PageTurnGestureContext {
        PageTurnGestureContext(
            availability: pageTurnAvailability,
            isAtBaseZoomScale: isAtBaseZoomScale,
            contentOffsetX: canvasView.contentOffset.x,
            contentSize: canvasView.contentSize,
            boundsSize: canvasView.bounds.size,
            contentInset: canvasView.contentInset,
            zoomScale: clampedCanvasZoomScale
        )
    }

    @discardableResult
    private func deliverPageTurn(_ direction: PageTurnDirection) -> Bool {
        let now = Date().timeIntervalSinceReferenceDate
        guard now - lastPageTurnDeliveryTime > 0.45 else {
            return false
        }

        lastPageTurnDeliveryTime = now
        activeInteractivePageTurnDirection = nil
        onPageTurn?(direction)
        return true
    }

    private func directionalTranslationX(_ translationX: CGFloat, for direction: PageTurnDirection) -> CGFloat {
        switch direction {
        case .previous:
            max(translationX, 0)
        case .next:
            min(translationX, 0)
        }
    }
}
