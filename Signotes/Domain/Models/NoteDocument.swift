import Foundation

struct NoteDocument: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var folderID: UUID
    var title: String
    var pageIDs: [UUID]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        folderID: UUID,
        title: String,
        pageIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.folderID = folderID
        self.title = title
        self.pageIDs = pageIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

