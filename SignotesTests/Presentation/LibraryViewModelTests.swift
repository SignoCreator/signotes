import XCTest
@testable import Signotes

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testCreateRootFolderDoesNotNestInsideSelectedFolder() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let viewModel = LibraryViewModel(notesRepository: repository)

        await viewModel.load()
        let originalRootID = try XCTUnwrap(viewModel.selectedRootFolderID)

        await viewModel.createRootFolder()

        let newRootID = try XCTUnwrap(viewModel.selectedRootFolderID)
        XCTAssertNotEqual(newRootID, originalRootID)
        XCTAssertEqual(viewModel.library.rootFolders.count, 2)
        XCTAssertNil(viewModel.library.parentFolder(of: newRootID))
        let originalRoot = try XCTUnwrap(viewModel.library.folder(id: originalRootID))
        XCTAssertFalse(originalRoot.childFolderIDs.contains(newRootID))
    }

    func testCreateChildFolderNestsInsideCurrentFolderAndCanNavigateBack() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let viewModel = LibraryViewModel(notesRepository: repository)

        await viewModel.load()
        let rootID = try XCTUnwrap(viewModel.selectedRootFolderID)

        await viewModel.createChildFolder()

        let childID = try XCTUnwrap(viewModel.currentFolderID)
        XCTAssertEqual(viewModel.selectedRootFolderID, rootID)
        XCTAssertEqual(viewModel.library.parentFolder(of: childID)?.id, rootID)
        XCTAssertEqual(viewModel.currentPath.map(\.id), [rootID, childID])

        viewModel.navigateToParentFolder()

        XCTAssertEqual(viewModel.currentFolderID, rootID)
        XCTAssertEqual(viewModel.selectedRootFolderID, rootID)
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
