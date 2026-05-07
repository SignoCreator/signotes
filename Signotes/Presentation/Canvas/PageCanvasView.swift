import PencilKit
import SwiftUI

struct PageCanvasView: View {
    let page: NotePage
    @Binding var drawing: PKDrawing
    let tool: any PKTool
    let toolKind: EditorDrawingTool
    let onDrawingChange: (PKDrawing) -> Void

    var body: some View {
        ZStack {
            PageBackgroundView(template: page.template)

            PencilCanvasRepresentable(
                drawing: $drawing,
                tool: tool,
                toolKind: toolKind,
                onDrawingChange: onDrawingChange
            )
        }
        .aspectRatio(page.format.aspectRatio, contentMode: .fit)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .shadow(color: .black.opacity(0.16), radius: 18, x: 0, y: 8)
    }
}
