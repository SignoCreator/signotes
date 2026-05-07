import XCTest
@testable import Signotes

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testCreateRootFolderDoesNotNestInsideSelectedFolder() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let viewModel = LibraryViewModel(notesRepository: repository)

        await viewModel.load()
        let originalRootID = try XCTUnwrap(viewModel.library.rootFolders.first?.id)

        await viewModel.createRootFolder(name: "Fisica", colorHex: "#4F8BFF")

        let newRootID = try XCTUnwrap(viewModel.selectedRootFolderID)
        XCTAssertNotEqual(newRootID, originalRootID)
        XCTAssertEqual(viewModel.library.rootFolders.count, 2)
        XCTAssertNil(viewModel.library.parentFolder(of: newRootID))
        XCTAssertEqual(viewModel.library.folder(id: newRootID)?.name, "Fisica")
        XCTAssertEqual(viewModel.library.folder(id: newRootID)?.colorHex, "#4F8BFF")
        let originalRoot = try XCTUnwrap(viewModel.library.folder(id: originalRootID))
        XCTAssertFalse(originalRoot.childFolderIDs.contains(newRootID))
    }

    func testLoadStartsAtRootGrid() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let viewModel = LibraryViewModel(notesRepository: repository)

        await viewModel.load()

        XCTAssertNil(viewModel.selectedRootFolderID)
        XCTAssertNil(viewModel.currentFolderID)
        XCTAssertEqual(viewModel.visibleChildFolders.map(\.name), ["Matematica"])
        XCTAssertTrue(viewModel.visibleNotes.isEmpty)
    }

    func testCreateChildFolderNestsInsideCurrentFolderAndCanNavigateBack() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let viewModel = LibraryViewModel(notesRepository: repository)

        await viewModel.load()
        let root = try XCTUnwrap(viewModel.library.rootFolders.first)
        viewModel.selectFolder(root)
        let rootID = root.id

        await viewModel.createChildFolder(name: "Analisi", colorHex: "#5AC8A8")

        let childID = try XCTUnwrap(viewModel.currentFolderID)
        XCTAssertEqual(viewModel.selectedRootFolderID, rootID)
        XCTAssertEqual(viewModel.library.parentFolder(of: childID)?.id, rootID)
        XCTAssertEqual(viewModel.library.folder(id: childID)?.name, "Analisi")
        XCTAssertEqual(viewModel.library.folder(id: childID)?.colorHex, "#5AC8A8")
        XCTAssertEqual(viewModel.currentPath.map(\.id), [rootID, childID])

        viewModel.navigateToParentFolder()

        XCTAssertEqual(viewModel.currentFolderID, rootID)
        XCTAssertEqual(viewModel.selectedRootFolderID, rootID)

        viewModel.navigateToParentFolder()

        XCTAssertNil(viewModel.currentFolderID)
        XCTAssertNil(viewModel.selectedRootFolderID)
    }

    func testCreateNoteStoresCustomTitleAndColor() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let viewModel = LibraryViewModel(notesRepository: repository)

        await viewModel.load()
        let root = try XCTUnwrap(viewModel.library.rootFolders.first)
        viewModel.selectFolder(root)

        await viewModel.createNote(title: "Integrali", colorHex: "#AF7AFF")

        let notes = viewModel.library.notes(in: root.id)
        let note = try XCTUnwrap(notes.first { $0.title == "Integrali" })
        XCTAssertEqual(note.colorHex, "#AF7AFF")
        XCTAssertEqual(viewModel.library.firstPage(in: note.id)?.template, .grid)
    }
}

private actor InMemoryNotesRepository: NotesRepository {
    private var snapshot: NoteLibrarySnapshot

    init(snapshot: NoteLibrarySnapshot) {
        self.snapshot = snapshot
    }

    func loadLibrary() async throws -> NoteLibrarySnapshot {
        snapshot
    }

    func saveLibrary(_ snapshot: NoteLibrarySnapshot) async throws {
        self.snapshot = snapshot
    }
}
