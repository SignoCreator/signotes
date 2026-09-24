import PencilKit
import SwiftUI

enum PageTurnDirection: Equatable, Sendable {
    case previous
    case next
}

enum PageTurnDragUpdate: Equatable, Sendable {
    case changed(direction: PageTurnDirection, translationX: CGFloat)
    case cancelled
}

enum EditorCanvasCommand: Equatable, Sendable {
    case undo
    case redo
}

struct EditorCanvasCommandRequest: Equatable, Sendable {
    let id = UUID()
    let command: EditorCanvasCommand
}

struct EditorCanvasCommandAvailability: Equatable, Sendable {
    var canUndo = false
    var canRedo = false
}

struct PageCanvasView: UIViewRepresentable {
    let page: NotePage
    let initialDrawing: PKDrawing
    let pageSize: CGSize
    let resetZoomToken: Int
    let commandRequest: EditorCanvasCommandRequest?
    let toolPreset: DrawingToolPreset
    let pageTurnAvailability: PageTurnAvailability
    let onDrawingChange: (PKDrawing) -> Void
    let onPageTurn: (PageTurnDirection) -> Void
    let onPageTurnDragUpdate: (PageTurnDragUpdate) -> Void
    let onCommandAvailabilityChange: (EditorCanvasCommandAvailability) -> Void

    func makeUIView(context: Context) -> PencilPageContainerView {
        let containerView = PencilPageContainerView()
        let coordinator = context.coordinator
        containerView.onDrawingChange = { drawing in
            coordinator.drawingDidChange(drawing)
        }
        containerView.onPageTurn = { direction in
            coordinator.pageTurnRequested(direction)
        }
        containerView.onPageTurnDragUpdate = { update in
            coordinator.pageTurnDragDidUpdate(update)
        }
        containerView.onCommandAvailabilityChange = { availability in
            coordinator.commandAvailabilityDidChange(availability)
        }
        containerView.configure(
            drawingResourceID: page.drawingResourceID,
            pageSize: pageSize,
            template: page.template,
            initialDrawing: initialDrawing,
            toolPreset: toolPreset,
            pageTurnAvailability: pageTurnAvailability,
            resetZoomToken: resetZoomToken
        )
        return containerView
    }

    func updateUIView(_ containerView: PencilPageContainerView, context: Context) {
        context.coordinator.parent = self
        containerView.configure(
            drawingResourceID: page.drawingResourceID,
            pageSize: pageSize,
            template: page.template,
            initialDrawing: initialDrawing,
            toolPreset: toolPreset,
            pageTurnAvailability: pageTurnAvailability,
            resetZoomToken: resetZoomToken
        )
        context.coordinator.applyCommandIfNeeded(commandRequest, to: containerView)
    }

    static func dismantleUIView(_ containerView: PencilPageContainerView, coordinator: Coordinator) {
        containerView.flushPendingDrawingChange()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator {
        var parent: PageCanvasView
        private var appliedCommandID: UUID?

        init(parent: PageCanvasView) {
            self.parent = parent
            appliedCommandID = parent.commandRequest?.id
        }

        func drawingDidChange(_ drawing: PKDrawing) {
            parent.onDrawingChange(drawing)
        }

        func pageTurnRequested(_ direction: PageTurnDirection) {
            parent.onPageTurn(direction)
        }

        func pageTurnDragDidUpdate(_ update: PageTurnDragUpdate) {
            parent.onPageTurnDragUpdate(update)
        }

        func commandAvailabilityDidChange(_ availability: EditorCanvasCommandAvailability) {
            parent.onCommandAvailabilityChange(availability)
        }

        func applyCommandIfNeeded(_ request: EditorCanvasCommandRequest?, to containerView: PencilPageContainerView) {
            guard let request, appliedCommandID != request.id else {
                return
            }

            appliedCommandID = request.id
            containerView.applyCanvasCommand(request.command)
        }
    }
}
