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
}
