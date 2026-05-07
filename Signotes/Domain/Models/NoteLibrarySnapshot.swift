import Foundation

struct NoteLibrarySnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var folders: [NotebookFolder]
    var notes: [NoteDocument]
    var pages: [NotePage]
    var toolPresets: [DrawingToolPreset]

    init(
        schemaVersion: Int = 1,
        folders: [NotebookFolder] = [],
        notes: [NoteDocument] = [],
        pages: [NotePage] = [],
        toolPresets: [DrawingToolPreset] = DrawingToolPreset.defaults
    ) {
        self.schemaVersion = schemaVersion
        self.folders = folders
        self.notes = notes
        self.pages = pages
        self.toolPresets = toolPresets
    }
}

extension NoteLibrarySnapshot {
    static let seed: NoteLibrarySnapshot = {
        let folderID = UUID(uuidString: "C0B6815B-F7E5-4304-91E9-89936DD8C1AE")!
        let noteID = UUID(uuidString: "F9F5A05B-153E-4A2B-9303-A4C7CF13F4D5")!
        let pageID = UUID(uuidString: "6E927823-FF62-490D-830B-08155D8FD740")!

        let page = NotePage(
            id: pageID,
            noteID: noteID,
            index: 0,
            format: .a4Portrait,
            template: .grid,
            drawingResourceID: "\(pageID.uuidString).drawing"
        )

        let note = NoteDocument(
            id: noteID,
            folderID: folderID,
            title: "Lezione 1",
            pageIDs: [pageID],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )

        let folder = NotebookFolder(
            id: folderID,
            name: "Matematica",
            noteIDs: [noteID]
        )

        return NoteLibrarySnapshot(
            folders: [folder],
            notes: [note],
            pages: [page]
        )
    }()
}

