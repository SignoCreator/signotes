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

    func testLibrarySupportsRecursiveFolders() throws {
        var library = NoteLibrarySnapshot()

        let root = try library.addFolder(name: "Matematica")
        let child = try library.addFolder(name: "Analisi", parentID: root.id)
        let note = try library.addNote(
            title: "Lezione 1",
            folderID: child.id,
            now: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(library.rootFolders.map(\.id), [root.id])
        XCTAssertEqual(library.childFolders(of: root.id).map(\.id), [child.id])
        XCTAssertEqual(library.notes(in: child.id).map(\.id), [note.id])
        XCTAssertEqual(library.firstPage(in: note.id)?.noteID, note.id)
        XCTAssertFalse(library.containsFolderCycle())
    }

    func testLibraryDetectsFolderCycles() throws {
        let rootID = UUID()
        let childID = UUID()

        let root = NotebookFolder(id: rootID, name: "Root", childFolderIDs: [childID])
        let child = NotebookFolder(id: childID, name: "Child", childFolderIDs: [rootID])
        let library = NoteLibrarySnapshot(folders: [root, child])

        XCTAssertTrue(library.containsFolderCycle())
    }
}
