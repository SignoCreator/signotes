import Foundation

struct NotePage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var noteID: UUID
    var index: Int
    var format: PageFormat
    var template: PageTemplate
    var drawingResourceID: String

    init(
        id: UUID = UUID(),
        noteID: UUID,
        index: Int,
        format: PageFormat,
        template: PageTemplate,
        drawingResourceID: String
    ) {
        self.id = id
        self.noteID = noteID
        self.index = index
        self.format = format
        self.template = template
        self.drawingResourceID = drawingResourceID
    }
}

