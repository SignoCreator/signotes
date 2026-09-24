import PencilKit
import SwiftUI

struct EditorPageDragState: Equatable {
    var direction: PageTurnDirection?
    var translationX: CGFloat = 0
    var isSettling = false

    static let inactive = EditorPageDragState()
}

struct EditorPageCarouselLayout: Equatable {
    let currentOffsetX: CGFloat
    let previousOffsetX: CGFloat
    let nextOffsetX: CGFloat

    init(dragState: EditorPageDragState, pageStride: CGFloat) {
        let offset = Self.currentPageOffset(dragState: dragState, pageStride: pageStride)
        currentOffsetX = offset
        previousOffsetX = -pageStride + offset
        nextOffsetX = pageStride + offset
    }

    private static func currentPageOffset(dragState: EditorPageDragState, pageStride: CGFloat) -> CGFloat {
        guard let direction = dragState.direction else {
            return 0
        }

        if dragState.isSettling {
            return direction == .next ? -pageStride : pageStride
        }

        let magnitude = min(abs(dragState.translationX), pageStride)
        return direction == .next ? -magnitude : magnitude
    }
}

struct EditorPageCarouselTarget {
    enum Destination: Equatable, Sendable {
        case existingPage(UUID)
        case appendNewPage(UUID)
    }

    let destination: Destination
    let preview: EditorPagePreview

    static func existingPage(
        _ page: NotePage,
        drawing: PKDrawing,
        drawingRevision: Int = 0
    ) -> EditorPageCarouselTarget {
        EditorPageCarouselTarget(
            destination: .existingPage(page.id),
            preview: EditorPagePreview(page: page, drawing: drawing, drawingRevision: drawingRevision)
        )
    }

    static func appendNewPage(id: UUID, template: PageTemplate) -> EditorPageCarouselTarget {
        EditorPageCarouselTarget(
            destination: .appendNewPage(id),
            preview: EditorPagePreview(id: id, template: template)
        )
    }
}

struct EditorPageTurnTarget: Equatable, Sendable {
    let direction: PageTurnDirection
    let destination: EditorPageCarouselTarget.Destination
}

struct EditorPageCarouselView: View {
    let page: NotePage
    let drawing: PKDrawing
    let pageSize: CGSize
    let resetZoomToken: Int
    let commandRequest: EditorCanvasCommandRequest?
    let toolPreset: DrawingToolPreset
    let previousTarget: EditorPageCarouselTarget?
    let nextTarget: EditorPageCarouselTarget
    let dragState: EditorPageDragState
    let onDrawingChange: (PKDrawing) -> Void
    let onPageTurn: (PageTurnDirection) -> Void
    let onPageTurnDragUpdate: (PageTurnDragUpdate) -> Void
    let onCommandAvailabilityChange: (EditorCanvasCommandAvailability) -> Void

    var body: some View {
        GeometryReader { geometry in
            let stride = geometry.size.width + 28
            let layout = EditorPageCarouselLayout(dragState: dragState, pageStride: stride)

            ZStack {
                if let previousTarget {
                    EditorPagePreviewView(preview: previousTarget.preview, pageSize: pageSize)
                        .offset(x: layout.previousOffsetX)
                }

                EditorPagePreviewView(preview: nextTarget.preview, pageSize: pageSize)
                    .offset(x: layout.nextOffsetX)

                PageCanvasView(
                    page: page,
                    initialDrawing: drawing,
                    pageSize: pageSize,
                    resetZoomToken: resetZoomToken,
                    commandRequest: commandRequest,
                    toolPreset: toolPreset,
                    pageTurnAvailability: PageTurnAvailability(
                        canTurnPrevious: previousTarget != nil,
                        canTurnNext: true
                    ),
                    onDrawingChange: onDrawingChange,
                    onPageTurn: onPageTurn,
                    onPageTurnDragUpdate: onPageTurnDragUpdate,
                    onCommandAvailabilityChange: onCommandAvailabilityChange
                )
                .id(page.id)
                .offset(x: layout.currentOffsetX)
                .zIndex(1)
            }
            .clipped()
        }
    }
}
