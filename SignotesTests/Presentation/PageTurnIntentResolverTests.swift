import XCTest
@testable import Signotes

final class PageTurnIntentResolverTests: XCTestCase {
    private let resolver = PageTurnIntentResolver()

    func testSwipeLeftOnNonScrollablePageRequestsNextPage() {
        let direction = resolver.direction(
            translation: CGPoint(x: -120, y: 8),
            contentOffsetX: -40,
            contentSize: CGSize(width: 300, height: 500),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40),
            zoomScale: 1
        )

        XCTAssertEqual(direction, .next)
    }

    func testSwipeRightOnNonScrollablePageRequestsPreviousPage() {
        let direction = resolver.direction(
            translation: CGPoint(x: 120, y: -5),
            contentOffsetX: -40,
            contentSize: CGSize(width: 300, height: 500),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40),
            zoomScale: 1
        )

        XCTAssertEqual(direction, .previous)
    }

    func testSwipeLeftOnScrollablePageRequiresTrailingEdge() {
        let direction = resolver.direction(
            translation: CGPoint(x: -120, y: 0),
            contentOffsetX: 200,
            contentSize: CGSize(width: 800, height: 1_000),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: .zero,
            zoomScale: 1
        )

        XCTAssertNil(direction)
    }

    func testSwipeLeftAtTrailingEdgeRequestsNextPage() {
        let direction = resolver.direction(
            translation: CGPoint(x: -120, y: 0),
            contentOffsetX: 300,
            contentSize: CGSize(width: 800, height: 1_000),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: .zero,
            zoomScale: 1
        )

        XCTAssertEqual(direction, .next)
    }

    func testVerticalPanDoesNotRequestPageTurn() {
        let direction = resolver.direction(
            translation: CGPoint(x: -90, y: 100),
            contentOffsetX: 300,
            contentSize: CGSize(width: 800, height: 1_000),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: .zero,
            zoomScale: 1
        )

        XCTAssertNil(direction)
    }

    func testInteractiveSwipeReportsDirectionBeforeCommitThreshold() {
        let direction = resolver.interactiveDirection(
            translation: CGPoint(x: -16, y: 1),
            contentOffsetX: -40,
            contentSize: CGSize(width: 300, height: 500),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 40),
            zoomScale: 1
        )

        XCTAssertEqual(direction, .next)
    }

    func testAvailableInteractiveSwipeTreatsExistingNextAndPreviousSymmetrically() {
        let availability = PageTurnAvailability(canTurnPrevious: true, canTurnNext: true)

        let nextDirection = resolver.interactiveDirection(
            translation: CGPoint(x: -16, y: 1),
            availability: availability
        )
        let previousDirection = resolver.interactiveDirection(
            translation: CGPoint(x: 16, y: -1),
            availability: availability
        )

        XCTAssertEqual(nextDirection, .next)
        XCTAssertEqual(previousDirection, .previous)
    }

    func testAvailableSwipeDoesNotReportUnavailablePreviousPage() {
        let direction = resolver.interactiveDirection(
            translation: CGPoint(x: 16, y: 0),
            availability: PageTurnAvailability(canTurnPrevious: false, canTurnNext: true)
        )

        XCTAssertNil(direction)
    }

    func testInteractiveSwipeStillRequiresHorizontalEdgeOnZoomedPage() {
        let direction = resolver.interactiveDirection(
            translation: CGPoint(x: -24, y: 1),
            contentOffsetX: 120,
            contentSize: CGSize(width: 800, height: 1_000),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: .zero,
            zoomScale: 1
        )

        XCTAssertNil(direction)
    }

    func testBaseZoomContextUsesAvailabilityInsteadOfScrollOffset() {
        let context = context(
            availability: PageTurnAvailability(canTurnPrevious: true, canTurnNext: true),
            isAtBaseZoomScale: true,
            contentOffsetX: 120
        )

        let nextDirection = resolver.interactiveDirection(
            translation: CGPoint(x: -16, y: 1),
            context: context
        )
        let previousDirection = resolver.interactiveDirection(
            translation: CGPoint(x: 16, y: 1),
            context: context
        )

        XCTAssertEqual(nextDirection, .next)
        XCTAssertEqual(previousDirection, .previous)
    }

    func testZoomedContextKeepsEdgeRequirementAndAvailabilityGuard() {
        let awayFromTrailingEdge = resolver.interactiveDirection(
            translation: CGPoint(x: -24, y: 1),
            context: context(
                availability: PageTurnAvailability(canTurnPrevious: true, canTurnNext: true),
                isAtBaseZoomScale: false,
                contentOffsetX: 120
            )
        )
        let unavailablePreviousAtLeadingEdge = resolver.interactiveDirection(
            translation: CGPoint(x: 24, y: 1),
            context: context(
                availability: PageTurnAvailability(canTurnPrevious: false, canTurnNext: true),
                isAtBaseZoomScale: false,
                contentOffsetX: 0
            )
        )

        XCTAssertNil(awayFromTrailingEdge)
        XCTAssertNil(unavailablePreviousAtLeadingEdge)
    }

    func testCommittedDirectionUsesActiveInteractiveDirection() {
        let context = context(
            availability: PageTurnAvailability(canTurnPrevious: true, canTurnNext: true),
            isAtBaseZoomScale: true
        )

        let direction = resolver.committedDirection(
            translation: CGPoint(x: -90, y: 0),
            activeDirection: .next,
            context: context
        )
        let rejectedDirection = resolver.committedDirection(
            translation: CGPoint(x: 90, y: 0),
            activeDirection: .next,
            context: context
        )

        XCTAssertEqual(direction, .next)
        XCTAssertNil(rejectedDirection)
    }

    func testTrackedInteractiveTurnCommitsFromDirectionAndTranslationOnly() {
        XCTAssertTrue(
            resolver.shouldCommitInteractiveTurn(
                direction: .next,
                translation: CGPoint(x: -90, y: 0)
            )
        )
        XCTAssertTrue(
            resolver.shouldCommitInteractiveTurn(
                direction: .previous,
                translation: CGPoint(x: 90, y: 0)
            )
        )
    }

    func testTrackedInteractiveTurnRejectsReversedOrShortTranslation() {
        XCTAssertFalse(
            resolver.shouldCommitInteractiveTurn(
                direction: .next,
                translation: CGPoint(x: 90, y: 0)
            )
        )
        XCTAssertFalse(
            resolver.shouldCommitInteractiveTurn(
                direction: .previous,
                translation: CGPoint(x: 40, y: 0)
            )
        )
    }

    private func context(
        availability: PageTurnAvailability,
        isAtBaseZoomScale: Bool,
        contentOffsetX: CGFloat = 0
    ) -> PageTurnGestureContext {
        PageTurnGestureContext(
            availability: availability,
            isAtBaseZoomScale: isAtBaseZoomScale,
            contentOffsetX: contentOffsetX,
            contentSize: CGSize(width: 800, height: 1_000),
            boundsSize: CGSize(width: 500, height: 600),
            contentInset: .zero,
            zoomScale: 1
        )
    }
}
