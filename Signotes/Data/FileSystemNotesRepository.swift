import Foundation

struct FileSystemNotesRepository: NotesRepository {
    private let rootURL: URL
    private let libraryURL: URL

    init(rootURL: URL) {
        self.rootURL = rootURL
        self.libraryURL = rootURL.appendingPathComponent("library.json")
    }

    func loadLibrary() async throws -> NoteLibrarySnapshot {
        try ensureRootDirectoryExists()

        guard FileManager.default.fileExists(atPath: libraryURL.path) else {
            let seed = NoteLibrarySnapshot.seed
            try await saveLibrary(seed)
            return seed
        }

        do {
            let data = try Data(contentsOf: libraryURL)
            return try JSONDecoder().decode(NoteLibrarySnapshot.self, from: data)
        } catch {
            throw LocalStorageError.corruptLibrary(libraryURL)
        }
    }

    func saveLibrary(_ snapshot: NoteLibrarySnapshot) async throws {
        try ensureRootDirectoryExists()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: libraryURL, options: [.atomic])
    }

    private func ensureRootDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true
        )
    }
}
