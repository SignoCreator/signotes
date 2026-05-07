import PencilKit
import SwiftUI

struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: any PKTool
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
        context.coordinator.configure(canvasView, tool: tool, toolKind: toolKind)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.parent = self

        if canvasView.drawing.dataRepresentation() != drawing.dataRepresentation() {
            canvasView.drawing = drawing
        }

        canvasView.overrideUserInterfaceStyle = .light

        context.coordinator.applyToolIfNeeded(tool, toolKind: toolKind, to: canvasView)
    }

    static func dismantleUIView(_ canvasView: PKCanvasView, coordinator: Coordinator) {
        coordinator.detach(from: canvasView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasRepresentable
        private let toolPicker: PKToolPicker
        private let toolPickerItemsByKind: [EditorDrawingTool: PKToolPickerItem]
        private var appliedToolKind: EditorDrawingTool?

        init(parent: PencilCanvasRepresentable) {
            let toolPickerPairs = EditorDrawingTool.allCases.map { ($0, $0.makeToolPickerItem()) }
            toolPickerItemsByKind = Dictionary(uniqueKeysWithValues: toolPickerPairs)
            toolPicker = PKToolPicker(toolItems: toolPickerPairs.map(\.1))
            self.parent = parent
        }

        func configure(_ canvasView: PKCanvasView, tool: any PKTool, toolKind: EditorDrawingTool) {
            canvasView.maximumSupportedContentVersion = .version3
            toolPicker.maximumSupportedContentVersion = .version3
            toolPicker.overrideUserInterfaceStyle = .light
            toolPicker.colorUserInterfaceStyle = .light
            toolPicker.showsDrawingPolicyControls = false
            toolPicker.addObserver(canvasView)

            applyTool(tool, toolKind: toolKind, to: canvasView)
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            canvasView.becomeFirstResponder()
        }

        func applyToolIfNeeded(_ tool: any PKTool, toolKind: EditorDrawingTool, to canvasView: PKCanvasView) {
            guard appliedToolKind != toolKind else {
                return
            }

            applyTool(tool, toolKind: toolKind, to: canvasView)
        }

        func detach(from canvasView: PKCanvasView) {
            toolPicker.removeObserver(canvasView)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChange(canvasView.drawing)
        }

        private func applyTool(_ tool: any PKTool, toolKind: EditorDrawingTool, to canvasView: PKCanvasView) {
            canvasView.tool = tool
            if let toolPickerItem = toolPickerItemsByKind[toolKind] {
                toolPicker.selectedToolItem = toolPickerItem
            }
            appliedToolKind = toolKind
        }
    }
}
