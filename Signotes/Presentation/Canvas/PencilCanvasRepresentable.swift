import PencilKit
import SwiftUI

struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let toolKind: EditorDrawingTool
    let onDrawingChange: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .pencilOnly
        canvasView.isOpaque = false
        canvasView.overrideUserInterfaceStyle = .light
        context.coordinator.configure(canvasView, toolKind: toolKind)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self

        if canvasView.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvasView.drawing = drawing
        }

        canvasView.overrideUserInterfaceStyle = .light

        context.coordinator.applyToolIfNeeded(toolKind, to: canvasView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasRepresentable
        private var appliedToolKind: EditorDrawingTool?

        init(parent: PencilCanvasRepresentable) {
            self.parent = parent
        }

        func configure(_ canvasView: PKCanvasView, toolKind: EditorDrawingTool) {
            canvasView.maximumSupportedContentVersion = .version3
            applyTool(toolKind, to: canvasView)
            canvasView.becomeFirstResponder()
        }

        func applyToolIfNeeded(_ toolKind: EditorDrawingTool, to canvasView: PKCanvasView) {
            guard appliedToolKind != toolKind else {
                return
            }

            applyTool(toolKind, to: canvasView)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChange(canvasView.drawing)
        }

        private func applyTool(_ toolKind: EditorDrawingTool, to canvasView: PKCanvasView) {
            canvasView.tool = toolKind.makeTool()
            appliedToolKind = toolKind
        }
    }
}
