import PencilKit
import SwiftUI

struct PageCanvasView: UIViewRepresentable {
    let page: NotePage
    let initialDrawing: PKDrawing
    let pageSize: CGSize
    let resetZoomToken: Int
    let toolKind: EditorDrawingTool
    let onDrawingChange: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PencilPageContainerView {
        let containerView = PencilPageContainerView()
        let coordinator = context.coordinator
        containerView.onDrawingChange = { drawing in
            coordinator.drawingDidChange(drawing)
        }
        containerView.configure(
            drawingResourceID: page.drawingResourceID,
            pageSize: pageSize,
            template: page.template,
            initialDrawing: initialDrawing,
            toolKind: toolKind,
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
            toolKind: toolKind,
            resetZoomToken: resetZoomToken
        )
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

        init(parent: PageCanvasView) {
            self.parent = parent
        }

        func drawingDidChange(_ drawing: PKDrawing) {
            parent.onDrawingChange(drawing)
        }
    }
}
