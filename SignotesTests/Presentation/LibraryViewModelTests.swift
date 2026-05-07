import XCTest
@testable import Signotes

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func testCreateRootFolderDoesNotNestInsideSelectedFolder() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

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
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()

        XCTAssertNil(viewModel.selectedRootFolderID)
        XCTAssertNil(viewModel.currentFolderID)
        XCTAssertEqual(viewModel.visibleChildFolders.map(\.name), ["Matematica"])
        XCTAssertTrue(viewModel.visibleNotes.isEmpty)
    }

    func testCreateChildFolderNestsInsideCurrentFolderAndCanNavigateBack() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

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
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()
        let root = try XCTUnwrap(viewModel.library.rootFolders.first)
        viewModel.selectFolder(root)

        await viewModel.createNote(title: "Integrali", colorHex: "#AF7AFF")

        let notes = viewModel.library.notes(in: root.id)
        let note = try XCTUnwrap(notes.first { $0.title == "Integrali" })
        XCTAssertEqual(note.colorHex, "#AF7AFF")
        XCTAssertEqual(viewModel.library.firstPage(in: note.id)?.template, .grid)
    }

    func testUpdateFolderAndNotePersistMetadata() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()
        let folder = try XCTUnwrap(viewModel.library.rootFolders.first)
        let note = try XCTUnwrap(viewModel.library.notes(in: folder.id).first)

        await viewModel.updateFolder(id: folder.id, name: "Algebra", colorHex: "#FF7A59")
        await viewModel.updateNote(id: note.id, title: "Matrici", colorHex: "#5AC8A8")

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertEqual(savedSnapshot.folder(id: folder.id)?.name, "Algebra")
        XCTAssertEqual(savedSnapshot.folder(id: folder.id)?.colorHex, "#FF7A59")
        XCTAssertEqual(savedSnapshot.note(id: note.id)?.title, "Matrici")
        XCTAssertEqual(savedSnapshot.note(id: note.id)?.colorHex, "#5AC8A8")
    }

    func testDeleteNoteUpdatesCurrentGridAndDeletesDrawingData() async throws {
        let repository = InMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()
        let folder = try XCTUnwrap(viewModel.library.rootFolders.first)
        viewModel.selectFolder(folder)
        let note = try XCTUnwrap(viewModel.visibleNotes.first)
        let resourceID = try XCTUnwrap(viewModel.library.firstPage(in: note.id)?.drawingResourceID)

        await viewModel.deleteNote(id: note.id)

        XCTAssertTrue(viewModel.visibleNotes.isEmpty)
        XCTAssertNil(viewModel.library.note(id: note.id))
        let deletedResourceIDs = await drawingRepository.deletedResourceIDs()
        XCTAssertEqual(deletedResourceIDs, [resourceID])
    }

    func testDeleteCurrentFolderNavigatesToParent() async throws {
        var snapshot = NoteLibrarySnapshot()
        let root = try snapshot.addFolder(name: "Matematica", colorHex: "#F2C94C")
        let child = try snapshot.addFolder(name: "Analisi", colorHex: "#4F8BFF", parentID: root.id)
        _ = try snapshot.addNote(title: "Integrali", colorHex: "#AF7AFF", folderID: child.id)
        let repository = InMemoryNotesRepository(snapshot: snapshot)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()
        viewModel.selectFolder(child)

        await viewModel.deleteFolder(id: child.id)

        XCTAssertEqual(viewModel.currentFolderID, root.id)
        XCTAssertEqual(viewModel.selectedRootFolderID, root.id)
        XCTAssertNil(viewModel.library.folder(id: child.id))
        XCTAssertTrue(viewModel.visibleChildFolders.isEmpty)
        XCTAssertTrue(viewModel.visibleNotes.isEmpty)
    }

    func testMoveDraggedNotePersistsDestinationFolder() async throws {
        var snapshot = NoteLibrarySnapshot()
        let source = try snapshot.addFolder(name: "Matematica")
        let destination = try snapshot.addFolder(name: "Fisica")
        let note = try snapshot.addNote(title: "Lezione 1", folderID: source.id)
        let repository = InMemoryNotesRepository(snapshot: snapshot)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()
        await viewModel.moveDraggedItems([.note(note.id)], toFolderID: destination.id)

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertFalse(savedSnapshot.folder(id: source.id)?.noteIDs.contains(note.id) ?? true)
        XCTAssertTrue(savedSnapshot.folder(id: destination.id)?.noteIDs.contains(note.id) ?? false)
        XCTAssertEqual(savedSnapshot.note(id: note.id)?.folderID, destination.id)
    }

    func testMoveDraggedFolderPersistsAndUpdatesCurrentRoot() async throws {
        var snapshot = NoteLibrarySnapshot()
        let sourceParent = try snapshot.addFolder(name: "Matematica")
        let destinationParent = try snapshot.addFolder(name: "Fisica")
        let child = try snapshot.addFolder(name: "Analisi", parentID: sourceParent.id)
        let repository = InMemoryNotesRepository(snapshot: snapshot)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()
        viewModel.selectFolder(child)
        await viewModel.moveDraggedItems([.folder(child.id)], toFolderID: destinationParent.id)

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertFalse(savedSnapshot.folder(id: sourceParent.id)?.childFolderIDs.contains(child.id) ?? true)
        XCTAssertTrue(savedSnapshot.folder(id: destinationParent.id)?.childFolderIDs.contains(child.id) ?? false)
        XCTAssertEqual(viewModel.currentFolderID, child.id)
        XCTAssertEqual(viewModel.selectedRootFolderID, destinationParent.id)
    }

    func testCanDropDraggedFolderRejectsSelfAndDescendantTargets() async throws {
        var snapshot = NoteLibrarySnapshot()
        let root = try snapshot.addFolder(name: "Matematica")
        let destination = try snapshot.addFolder(name: "Fisica")
        let child = try snapshot.addFolder(name: "Analisi", parentID: root.id)
        let grandchild = try snapshot.addFolder(name: "Serie", parentID: child.id)
        let repository = InMemoryNotesRepository(snapshot: snapshot)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()

        XCTAssertFalse(viewModel.canDropDraggedItems([.folder(child.id)], toFolderID: child.id))
        XCTAssertFalse(viewModel.canDropDraggedItems([.folder(child.id)], toFolderID: grandchild.id))
        XCTAssertFalse(viewModel.canDropDraggedItems([.folder(child.id)], toFolderID: root.id))
        XCTAssertTrue(viewModel.canDropDraggedItems([.folder(child.id)], toFolderID: destination.id))
    }

    func testCanDropDraggedNoteRejectsRootAndSameFolder() async throws {
        var snapshot = NoteLibrarySnapshot()
        let source = try snapshot.addFolder(name: "Matematica")
        let destination = try snapshot.addFolder(name: "Fisica")
        let note = try snapshot.addNote(title: "Lezione 1", folderID: source.id)
        let repository = InMemoryNotesRepository(snapshot: snapshot)
        let drawingRepository = InMemoryDrawingRepository()
        let viewModel = LibraryViewModel(notesRepository: repository, drawingRepository: drawingRepository)

        await viewModel.load()

        XCTAssertFalse(viewModel.canDropDraggedItems([.note(note.id)], toFolderID: nil))
        XCTAssertFalse(viewModel.canDropDraggedItems([.note(note.id)], toFolderID: source.id))
        XCTAssertTrue(viewModel.canDropDraggedItems([.note(note.id)], toFolderID: destination.id))
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

    func currentSnapshot() -> NoteLibrarySnapshot {
        snapshot
    }
}

private actor InMemoryDrawingRepository: DrawingRepository {
    private var dataByResourceID: [String: Data] = [:]
    private var deletedIDs: [String] = []

    func loadDrawingData(resourceID: String) async throws -> Data? {
        dataByResourceID[resourceID]
    }

    func saveDrawingData(_ data: Data, resourceID: String) async throws {
        dataByResourceID[resourceID] = data
    }

    func deleteDrawingData(resourceID: String) async throws {
        dataByResourceID[resourceID] = nil
        deletedIDs.append(resourceID)
    }

    func deletedResourceIDs() -> [String] {
        deletedIDs
    }
}
