import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var library = NoteLibrarySnapshot()
    @Published var selectedRootFolderID: UUID?
    @Published private(set) var currentFolderID: UUID?
    @Published var errorMessage: String?

    private let notesRepository: NotesRepository
    private let drawingRepository: DrawingRepository

    init(notesRepository: NotesRepository, drawingRepository: DrawingRepository) {
        self.notesRepository = notesRepository
        self.drawingRepository = drawingRepository
    }

    var rootFolders: [NotebookFolder] {
        library.rootFolders
    }

    var selectedRootFolder: NotebookFolder? {
        guard let selectedRootFolderID else {
            return nil
        }

        return library.folder(id: selectedRootFolderID)
    }

    var currentFolder: NotebookFolder? {
        guard let currentFolderID else {
            return nil
        }

        return library.folder(id: currentFolderID)
    }

    var parentFolder: NotebookFolder? {
        guard let currentFolderID else {
            return nil
        }

        return library.parentFolder(of: currentFolderID)
    }

    var currentPath: [NotebookFolder] {
        guard let currentFolderID else {
            return []
        }

        return library.folderPath(to: currentFolderID)
    }

    var visibleChildFolders: [NotebookFolder] {
        library.childFolders(of: currentFolderID)
    }

    var visibleNotes: [NoteDocument] {
        guard let currentFolderID else {
            return []
        }

        return library.notes(in: currentFolderID)
    }

    func load() async {
        do {
            library = try await notesRepository.loadLibrary()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectRootFolder(id: UUID?) {
        selectedRootFolderID = id
        currentFolderID = id
    }

    func selectFolder(_ folder: NotebookFolder) {
        currentFolderID = folder.id
        selectedRootFolderID = library.rootFolder(containing: folder.id)?.id
    }

    func navigateToParentFolder() {
        guard let currentFolderID else {
            return
        }

        if let parentFolder = library.parentFolder(of: currentFolderID) {
            selectFolder(parentFolder)
        } else {
            selectedRootFolderID = nil
            self.currentFolderID = nil
        }
    }

    func createRootFolder(name: String, colorHex: String) async {
        do {
            var updatedLibrary = library
            let folder = try updatedLibrary.addFolder(name: name, colorHex: colorHex)
            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary
            selectRootFolder(id: folder.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createChildFolder(name: String, colorHex: String) async {
        guard let currentFolderID else {
            return
        }

        do {
            var updatedLibrary = library
            let folder = try updatedLibrary.addFolder(
                name: name,
                colorHex: colorHex,
                parentID: currentFolderID
            )
            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary
            selectFolder(folder)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createNote(title: String, colorHex: String) async {
        guard let currentFolderID else {
            return
        }

        do {
            var updatedLibrary = library
            _ = try updatedLibrary.addNote(
                title: title,
                colorHex: colorHex,
                folderID: currentFolderID
            )
            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFolder(id: UUID, name: String, colorHex: String) async {
        do {
            var updatedLibrary = library
            try updatedLibrary.updateFolder(id: id, name: name, colorHex: colorHex)
            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateNote(id: UUID, title: String, colorHex: String) async {
        do {
            var updatedLibrary = library
            try updatedLibrary.updateNote(id: id, title: title, colorHex: colorHex)
            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteNote(id: UUID) async {
        do {
            var updatedLibrary = library
            let drawingResourceIDs = try updatedLibrary.deleteNote(id: id)
            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary
            await deleteDrawingsAndSurfaceErrors(resourceIDs: drawingResourceIDs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteFolder(id: UUID) async {
        do {
            var updatedLibrary = library
            let destinationFolderID = navigationDestinationAfterDeletingFolder(id: id)
            let drawingResourceIDs = try updatedLibrary.deleteFolderTree(id: id)

            try await notesRepository.saveLibrary(updatedLibrary)

            library = updatedLibrary
            selectFolderID(destinationFolderID)
            await deleteDrawingsAndSurfaceErrors(resourceIDs: drawingResourceIDs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveDraggedItems(_ items: [LibraryDragItem], toFolderID targetFolderID: UUID?) async {
        do {
            var updatedLibrary = library

            let movableItems = items.filter {
                canDrop($0, toFolderID: targetFolderID, in: updatedLibrary)
            }

            guard !movableItems.isEmpty else {
                return
            }

            for item in movableItems {
                switch item {
                case let .folder(folderID):
                    if let targetFolderID {
                        try updatedLibrary.moveFolder(id: folderID, toFolderID: targetFolderID)
                    } else {
                        try updatedLibrary.moveFolderToRoot(id: folderID)
                    }
                case let .note(noteID):
                    guard let targetFolderID else {
                        continue
                    }

                    try updatedLibrary.moveNote(id: noteID, toFolderID: targetFolderID)
                }
            }

            try await notesRepository.saveLibrary(updatedLibrary)
            library = updatedLibrary

            if let currentFolderID {
                selectFolderID(currentFolderID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func canDropDraggedItems(_ items: [LibraryDragItem], toFolderID targetFolderID: UUID?) -> Bool {
        !items.isEmpty && items.allSatisfy {
            canDrop($0, toFolderID: targetFolderID, in: library)
        }
    }

    private func selectFolderID(_ folderID: UUID?) {
        guard let folderID, let folder = library.folder(id: folderID) else {
            selectRootFolder(id: nil)
            return
        }

        selectFolder(folder)
    }

    private func navigationDestinationAfterDeletingFolder(id: UUID) -> UUID? {
        guard let currentFolderID, library.folderPathContains(folderID: currentFolderID, candidateID: id) else {
            return self.currentFolderID
        }

        return library.parentFolder(of: id)?.id
    }

    private func deleteDrawings(resourceIDs: [String]) async throws {
        for resourceID in resourceIDs {
            try await drawingRepository.deleteDrawingData(resourceID: resourceID)
        }
    }

    private func deleteDrawingsAndSurfaceErrors(resourceIDs: [String]) async {
        do {
            try await deleteDrawings(resourceIDs: resourceIDs)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func canDrop(
        _ item: LibraryDragItem,
        toFolderID targetFolderID: UUID?,
        in library: NoteLibrarySnapshot
    ) -> Bool {
        switch item {
        case let .folder(folderID):
            guard library.folder(id: folderID) != nil else {
                return false
            }

            guard let targetFolderID else {
                return library.parentFolder(of: folderID) != nil
            }

            guard library.folder(id: targetFolderID) != nil else {
                return false
            }

            guard folderID != targetFolderID else {
                return false
            }

            guard library.parentFolder(of: folderID)?.id != targetFolderID else {
                return false
            }

            return !library.folderPathContains(folderID: targetFolderID, candidateID: folderID)
        case let .note(noteID):
            guard let targetFolderID,
                  let note = library.note(id: noteID),
                  library.folder(id: targetFolderID) != nil else {
                return false
            }

            return note.folderID != targetFolderID
        }
    }
}
