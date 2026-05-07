protocol NotesRepository: Sendable {
    func loadLibrary() async throws -> NoteLibrarySnapshot
    func saveLibrary(_ snapshot: NoteLibrarySnapshot) async throws
}

