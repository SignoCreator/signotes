import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var library = NoteLibrarySnapshot()
    @Published var selectedRootFolderID: UUID?
    @Published private(set) var currentFolderID: UUID?
    @Published var errorMessage: String?

    private let notesRepository: NotesRepository

    init(notesRepository: NotesRepository) {
        self.notesRepository = notesRepository
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
}
