import XCTest
@testable import Signotes

final class DomainModelTests: XCTestCase {
    func testA4PortraitAspectRatio() {
        XCTAssertEqual(
            PageFormat.a4Portrait.aspectRatio,
            210.0 / 297.0,
            accuracy: 0.000_001
        )
    }

    func testSeedLibraryContainsInitialMathNote() {
        let seed = NoteLibrarySnapshot.seed

        XCTAssertEqual(seed.schemaVersion, 1)
        XCTAssertEqual(seed.folders.count, 1)
        XCTAssertEqual(seed.folders.first?.name, "Matematica")
        XCTAssertEqual(seed.notes.count, 1)
        XCTAssertEqual(seed.notes.first?.title, "Lezione 1")
        XCTAssertEqual(seed.pages.count, 1)
        XCTAssertEqual(seed.pages.first?.template, .grid)
    }

    func testSeedLibraryJSONRoundTrip() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(NoteLibrarySnapshot.seed)
        let decoded = try decoder.decode(NoteLibrarySnapshot.self, from: data)

        XCTAssertEqual(decoded, NoteLibrarySnapshot.seed)
    }
}

