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
            "Elimina cartella?"
        case .note:
            "Elimina lezione?"
        }
    }

    var message: String {
        switch self {
        case let .folder(folder):
            "La cartella \"\(folder.name)\" e tutto il suo contenuto verranno eliminati definitivamente."
        case let .note(note):
            "La lezione \"\(note.title)\" e le sue pagine verranno eliminate definitivamente."
        }
    }
}
