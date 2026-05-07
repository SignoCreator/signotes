import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var library = NoteLibrarySnapshot()
    @Published var selectedFolderID: UUID?
    @Published var errorMessage: String?

    private let notesRepository: NotesRepository

    init(notesRepository: NotesRepository) {
        self.notesRepository = notesRepository
    }

    var rootFolders: [NotebookFolder] {
        library.rootFolders
    }

    var selectedFolder: NotebookFolder? {
        guard let selectedFolderID else {
            return rootFolders.first
        }

        return library.folder(id: selectedFolderID)
    }

    var visibleChildFolders: [NotebookFolder] {
        library.childFolders(of: selectedFolder?.id)
    }

    var visibleNotes: [NoteDocument] {
        guard let folderID = selectedFolder?.id else {
            return []
        }

        return library.notes(in: folderID)
    }

    func load() async {
        do {
            library = try await notesRepository.loadLibrary()
            selectedFolderID = selectedFolderID ?? library.rootFolders.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectFolder(_ folder: NotebookFolder) {
        selectedFolderID = folder.id
    }

    func createFolder() {
        Task {
            do {
                var updatedLibrary = library
                let folder = try updatedLibrary.addFolder(
                    name: "Nuova cartella",
                    parentID: selectedFolder?.id
                )
                try await notesRepository.saveLibrary(updatedLibrary)
                library = updatedLibrary
                selectedFolderID = folder.id
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func createNote() {
        guard let folderID = selectedFolder?.id else {
            return
        }

        Task {
            do {
                var updatedLibrary = library
                _ = try updatedLibrary.addNote(title: "Nuova lezione", folderID: folderID)
                try await notesRepository.saveLibrary(updatedLibrary)
                library = updatedLibrary
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
