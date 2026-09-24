import PencilKit
import XCTest
@testable import Signotes

final class EditorPageCarouselLayoutTests: XCTestCase {
    func testInactiveLayoutKeepsAdjacentPagesPrepositionedOffscreen() {
        let layout = EditorPageCarouselLayout(
            dragState: .inactive,
            pageStride: 500
        )

        XCTAssertEqual(layout.currentOffsetX, 0)
        XCTAssertEqual(layout.previousOffsetX, -500)
        XCTAssertEqual(layout.nextOffsetX, 500)
    }

    func testInteractiveNextAndPreviousOffsetsAreSymmetric() {
        let nextLayout = EditorPageCarouselLayout(
            dragState: EditorPageDragState(direction: .next, translationX: -120),
            pageStride: 500
        )
        let previousLayout = EditorPageCarouselLayout(
            dragState: EditorPageDragState(direction: .previous, translationX: 120),
            pageStride: 500
        )

        XCTAssertEqual(nextLayout.currentOffsetX, -120)
        XCTAssertEqual(nextLayout.nextOffsetX, 380)
        XCTAssertEqual(previousLayout.currentOffsetX, 120)
        XCTAssertEqual(previousLayout.previousOffsetX, -380)
    }

    func testSettledNextAndPreviousOffsetsAreSymmetric() {
        let nextLayout = EditorPageCarouselLayout(
            dragState: EditorPageDragState(direction: .next, translationX: -120, isSettling: true),
            pageStride: 500
        )
        let previousLayout = EditorPageCarouselLayout(
            dragState: EditorPageDragState(direction: .previous, translationX: 120, isSettling: true),
            pageStride: 500
        )

        XCTAssertEqual(nextLayout.currentOffsetX, -500)
        XCTAssertEqual(nextLayout.nextOffsetX, 0)
        XCTAssertEqual(previousLayout.currentOffsetX, 500)
        XCTAssertEqual(previousLayout.previousOffsetX, 0)
    }

    func testExistingPageTargetKeepsPageIdentityExplicit() {
        let noteID = UUID()
        let pageID = UUID()
        let page = NotePage(
            id: pageID,
            noteID: noteID,
            index: 1,
            format: .a4Portrait,
            template: .grid,
            drawingResourceID: "page.drawing"
        )
        let target = EditorPageCarouselTarget.existingPage(page, drawing: PKDrawing())

        XCTAssertEqual(target.destination, .existingPage(pageID))
        XCTAssertEqual(target.preview.id, pageID)
    }

    func testAppendPageTargetIsKnownBeforeTheDragCommits() {
        let appendSlotID = UUID()
        let target = EditorPageCarouselTarget.appendNewPage(id: appendSlotID, template: .dotted)

        XCTAssertEqual(target.destination, .appendNewPage(appendSlotID))
        XCTAssertEqual(target.preview.id, appendSlotID)
        XCTAssertEqual(target.preview.template, .dotted)
    }
}
