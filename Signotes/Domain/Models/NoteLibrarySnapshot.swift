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
    var rootFolders: [NotebookFolder] {
        let childIDs = Set(folders.flatMap(\.childFolderIDs))
        return folders
            .filter { !childIDs.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func folder(id: UUID) -> NotebookFolder? {
        folders.first { $0.id == id }
    }

    func parentFolder(of folderID: UUID) -> NotebookFolder? {
        folders.first { $0.childFolderIDs.contains(folderID) }
    }

    func rootFolder(containing folderID: UUID) -> NotebookFolder? {
        var currentID = folderID
        var visited = Set<UUID>()

        while let parent = parentFolder(of: currentID), !visited.contains(parent.id) {
            visited.insert(parent.id)
            currentID = parent.id
        }

        return folder(id: currentID)
    }

    func folderPath(to folderID: UUID) -> [NotebookFolder] {
        guard let folder = folder(id: folderID) else {
            return []
        }

        if let parent = parentFolder(of: folderID) {
            return folderPath(to: parent.id) + [folder]
        }

        return [folder]
    }

    func childFolders(of folderID: UUID?) -> [NotebookFolder] {
        guard let folderID, let folder = folder(id: folderID) else {
            return rootFolders
        }

        let childIDs = Set(folder.childFolderIDs)
        return folders
            .filter { childIDs.contains($0.id) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func notes(in folderID: UUID) -> [NoteDocument] {
        guard let folder = folder(id: folderID) else {
            return []
        }

        let noteIDs = Set(folder.noteIDs)
        return notes
            .filter { noteIDs.contains($0.id) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func note(id: UUID) -> NoteDocument? {
        notes.first { $0.id == id }
    }

    func firstPage(in noteID: UUID) -> NotePage? {
        guard let note = note(id: noteID) else {
            return nil
        }

        let pageIDs = Set(note.pageIDs)
        return pages
            .filter { pageIDs.contains($0.id) }
            .sorted { $0.index < $1.index }
            .first
    }

    mutating func addFolder(
        name: String,
        colorHex: String? = nil,
        parentID: UUID? = nil,
        id: UUID = UUID()
    ) throws -> NotebookFolder {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let folder = NotebookFolder(
            id: id,
            name: trimmedName.isEmpty ? "Nuova cartella" : trimmedName,
            colorHex: colorHex
        )

        if let parentID {
            guard let parentIndex = folders.firstIndex(where: { $0.id == parentID }) else {
                throw LibraryMutationError.folderNotFound(parentID)
            }

            folders[parentIndex].childFolderIDs.append(folder.id)
        }

        folders.append(folder)
        return folder
    }

    mutating func addNote(
        title: String,
        colorHex: String? = nil,
        folderID: UUID,
        now: Date = Date()
    ) throws -> NoteDocument {
        guard let folderIndex = folders.firstIndex(where: { $0.id == folderID }) else {
            throw LibraryMutationError.folderNotFound(folderID)
        }

        let noteID = UUID()
        let pageID = UUID()
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

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
            title: trimmedTitle.isEmpty ? "Nuova lezione" : trimmedTitle,
            colorHex: colorHex,
            pageIDs: [pageID],
            createdAt: now,
            updatedAt: now
        )

        folders[folderIndex].noteIDs.append(note.id)
        notes.append(note)
        pages.append(page)

        return note
    }

    mutating func updateFolder(id: UUID, name: String, colorHex: String?) throws {
        guard let folderIndex = folders.firstIndex(where: { $0.id == id }) else {
            throw LibraryMutationError.folderNotFound(id)
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        folders[folderIndex].name = trimmedName.isEmpty ? folders[folderIndex].name : trimmedName
        folders[folderIndex].colorHex = colorHex
    }

    mutating func updateNote(id: UUID, title: String, colorHex: String?, now: Date = Date()) throws {
        guard let noteIndex = notes.firstIndex(where: { $0.id == id }) else {
            throw LibraryMutationError.noteNotFound(id)
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        notes[noteIndex].title = trimmedTitle.isEmpty ? notes[noteIndex].title : trimmedTitle
        notes[noteIndex].colorHex = colorHex
        notes[noteIndex].updatedAt = now
    }

    mutating func deleteNote(id: UUID) throws -> [String] {
        guard let note = note(id: id) else {
            throw LibraryMutationError.noteNotFound(id)
        }

        let pageIDs = Set(note.pageIDs)
        let drawingResourceIDs = pages
            .filter { pageIDs.contains($0.id) }
            .map(\.drawingResourceID)

        pages.removeAll { pageIDs.contains($0.id) }
        notes.removeAll { $0.id == id }

        if let folderIndex = folders.firstIndex(where: { $0.id == note.folderID }) {
            folders[folderIndex].noteIDs.removeAll { $0 == id }
        }

        return drawingResourceIDs
    }

    mutating func deleteFolderTree(id: UUID) throws -> [String] {
        guard folder(id: id) != nil else {
            throw LibraryMutationError.folderNotFound(id)
        }

        let folderIDs = descendantFolderIDs(including: id)
        let noteIDs = Set(notes.filter { folderIDs.contains($0.folderID) }.map(\.id))
        let pageIDs = Set(pages.filter { noteIDs.contains($0.noteID) }.map(\.id))
        let drawingResourceIDs = pages
            .filter { pageIDs.contains($0.id) }
            .map(\.drawingResourceID)

        folders.removeAll { folderIDs.contains($0.id) }
        notes.removeAll { noteIDs.contains($0.id) }
        pages.removeAll { pageIDs.contains($0.id) }

        for index in folders.indices {
            folders[index].childFolderIDs.removeAll { folderIDs.contains($0) }
            folders[index].noteIDs.removeAll { noteIDs.contains($0) }
        }

        return drawingResourceIDs
    }

    func folderPathContains(folderID: UUID, candidateID: UUID) -> Bool {
        folderPath(to: folderID).contains { $0.id == candidateID }
    }

    func containsFolderCycle() -> Bool {
        let childrenByFolderID = Dictionary(uniqueKeysWithValues: folders.map { ($0.id, $0.childFolderIDs) })
        var visited = Set<UUID>()
        var visiting = Set<UUID>()

        func visit(_ folderID: UUID) -> Bool {
            if visiting.contains(folderID) {
                return true
            }

            if visited.contains(folderID) {
                return false
            }

            visiting.insert(folderID)
            for childID in childrenByFolderID[folderID, default: []] where visit(childID) {
                return true
            }
            visiting.remove(folderID)
            visited.insert(folderID)
            return false
        }

        return folders.contains { visit($0.id) }
    }

    private func descendantFolderIDs(including folderID: UUID) -> Set<UUID> {
        guard let folder = folder(id: folderID) else {
            return []
        }

        return folder.childFolderIDs.reduce(into: Set([folderID])) { result, childID in
            result.formUnion(descendantFolderIDs(including: childID))
        }
    }
}

enum LibraryMutationError: Error, Equatable {
    case folderNotFound(UUID)
    case noteNotFound(UUID)
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
