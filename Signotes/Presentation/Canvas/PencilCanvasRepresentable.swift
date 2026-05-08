import PencilKit
import SwiftUI

struct PencilCanvasRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: any PKTool
    let toolKind: EditorDrawingTool
    let onDrawingChange: (PKDrawing) -> Void
    let onToolChange: (EditorDrawingTool) -> Void

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

    static func dismantleUIView(_ canvasView: PKCanvasView, coordinator: Coordinator) {
        coordinator.detach(from: canvasView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate, PKToolPickerObserver {
        var parent: PencilCanvasRepresentable
        private let toolPicker: PKToolPicker
        private let toolPickerItemsByKind: [EditorDrawingTool: PKToolPickerItem]
        private let toolKindsByItemIdentifier: [String: EditorDrawingTool]
        private var appliedToolKind: EditorDrawingTool?
        private var isApplyingToolProgrammatically = false

        init(parent: PencilCanvasRepresentable) {
            let toolPickerPairs = EditorDrawingTool.allCases.map { ($0, $0.makeToolPickerItem()) }
            toolPickerItemsByKind = Dictionary(uniqueKeysWithValues: toolPickerPairs)
            toolKindsByItemIdentifier = Dictionary(
                uniqueKeysWithValues: toolPickerPairs.map { ($0.1.identifier, $0.0) }
            )
            toolPicker = PKToolPicker(toolItems: toolPickerPairs.map(\.1))
            self.parent = parent
        }

        func configure(_ canvasView: PKCanvasView, toolKind: EditorDrawingTool) {
            canvasView.maximumSupportedContentVersion = .version3
            toolPicker.maximumSupportedContentVersion = .version3
            toolPicker.overrideUserInterfaceStyle = .light
            toolPicker.colorUserInterfaceStyle = .light
            toolPicker.showsDrawingPolicyControls = false
            toolPicker.addObserver(canvasView)
            toolPicker.addObserver(self)

            applyTool(toolKind, to: canvasView)
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            canvasView.becomeFirstResponder()
        }

        func applyToolIfNeeded(_ toolKind: EditorDrawingTool, to canvasView: PKCanvasView) {
            guard appliedToolKind != toolKind else {
                return
            }

            applyTool(toolKind, to: canvasView)
        }

        func detach(from canvasView: PKCanvasView) {
            toolPicker.removeObserver(canvasView)
            toolPicker.removeObserver(self)
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.onDrawingChange(canvasView.drawing)
        }

        func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
            guard !isApplyingToolProgrammatically else {
                return
            }

            let selectedIdentifier = toolPicker.selectedToolItemIdentifier
            guard let selectedToolKind = toolKindsByItemIdentifier[selectedIdentifier] else {
                return
            }

            appliedToolKind = selectedToolKind
            parent.onToolChange(selectedToolKind)
        }

        private func applyTool(_ toolKind: EditorDrawingTool, to canvasView: PKCanvasView) {
            let tool = toolKind.makeTool()

            isApplyingToolProgrammatically = true
            defer { isApplyingToolProgrammatically = false }

            if let toolPickerItem = toolPickerItemsByKind[toolKind] {
                toolPicker.selectedToolItem = toolPickerItem
            }
            canvasView.tool = tool
            appliedToolKind = toolKind
        }
    }
}
