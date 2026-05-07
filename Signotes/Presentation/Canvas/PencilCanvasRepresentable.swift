import PencilKit
import SwiftUI

struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: PKTool
    let onDrawingChange: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .pencilOnly
        canvasView.isOpaque = false
        canvasView.tool = tool
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self

        if canvasView.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvasView.drawing = drawing
        }

        canvasView.tool = tool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasRepresentable

        init(parent: PencilCanvasRepresentable) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChange(canvasView.drawing)
        }
    }
}

