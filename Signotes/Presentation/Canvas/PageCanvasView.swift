import PencilKit
import SwiftUI

enum PageTurnDirection {
    case previous
    case next
}

enum EditorCanvasCommand {
    case undo
    case redo
}

struct EditorCanvasCommandRequest: Equatable {
    let id = UUID()
    let command: EditorCanvasCommand
}

struct EditorCanvasCommandAvailability: Equatable {
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
    let onDrawingChange: (PKDrawing) -> Void
    let onPageTurn: (PageTurnDirection) -> Void
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
        containerView.onCommandAvailabilityChange = { availability in
            coordinator.commandAvailabilityDidChange(availability)
        }
        containerView.configure(
            drawingResourceID: page.drawingResourceID,
            pageSize: pageSize,
            template: page.template,
            initialDrawing: initialDrawing,
            toolPreset: toolPreset,
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
