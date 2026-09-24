import Foundation

enum LibraryDeletionRequest: Identifiable {
    case folder(NotebookFolder)
    case note(NoteDocument)

    var id: UUID {
        switch self {
        case let .folder(folder):
            folder.id
        case let .note(note):
            note.id
        }
    }

    var title: String {
        switch self {
        case .folder:
            "Delete folder?"
        case .note:
            "Delete note?"
        }
    }

    var message: String {
        switch self {
        case let .folder(folder):
            "The folder \"\(folder.name)\" and everything in it will be permanently deleted."
        case let .note(note):
            "The note \"\(note.title)\" and its pages will be permanently deleted."
        }
    }
}
