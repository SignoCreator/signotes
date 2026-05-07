import Foundation

struct NotebookFolder: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var noteIDs: [UUID]
    var childFolderIDs: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        noteIDs: [UUID] = [],
        childFolderIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.noteIDs = noteIDs
        self.childFolderIDs = childFolderIDs
    }
}

