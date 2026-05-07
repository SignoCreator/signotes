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

        let root = try library.addFolder(name: "Matematica", colorHex: "#F2C94C")
        let child = try library.addFolder(name: "Analisi", colorHex: "#4F8BFF", parentID: root.id)
        let note = try library.addNote(
            title: "Lezione 1",
            colorHex: "#5AC8A8",
            folderID: child.id,
            now: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(library.rootFolders.map(\.id), [root.id])
        XCTAssertEqual(library.childFolders(of: root.id).map(\.id), [child.id])
        XCTAssertEqual(library.notes(in: child.id).map(\.id), [note.id])
        XCTAssertEqual(library.folder(id: root.id)?.colorHex, "#F2C94C")
        XCTAssertEqual(library.folder(id: child.id)?.colorHex, "#4F8BFF")
        XCTAssertEqual(library.note(id: note.id)?.colorHex, "#5AC8A8")
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
