import CoreGraphics
import XCTest
@testable import Signotes

final class CanvasViewportConfigurationTests: XCTestCase {
    func testFitToWidthScaleUsesViewportWidthMinusPadding() {
        let configuration = CanvasViewportConfiguration(
            pageSize: CGSize(width: 794, height: 1123),
            viewportSize: CGSize(width: 842, height: 1190),
            horizontalPadding: 48
        )

        XCTAssertEqual(configuration.fitToWidthScale, 1, accuracy: 0.000_001)
        XCTAssertEqual(configuration.minimumZoomScale, 1, accuracy: 0.000_001)
    }

    func testZoomScaleIsClampedBetweenFitWidthAndMaximum() {
        let configuration = CanvasViewportConfiguration(
            pageSize: CGSize(width: 794, height: 1123),
            viewportSize: CGSize(width: 445, height: 900),
            horizontalPadding: 48,
            maxZoomScale: 4
        )

        XCTAssertEqual(configuration.minimumZoomScale, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(configuration.clampedZoomScale(0.2), 0.5, accuracy: 0.000_001)
        XCTAssertEqual(configuration.clampedZoomScale(2), 2, accuracy: 0.000_001)
        XCTAssertEqual(configuration.clampedZoomScale(8), 4, accuracy: 0.000_001)
    }
}
