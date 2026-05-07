# Exec Plan 02: Local Persistence

## Objective

Implement local-first storage for library metadata and page drawing blobs behind repository protocols.

## Context

The MVP is offline-first. Metadata should be human-inspectable JSON. Drawings should be stored per page so large notes can load incrementally. PencilKit serialization must be isolated outside Domain.

Relevant reference:

- PencilKit `PKDrawing` storage APIs: https://developer.apple.com/documentation/pencilkit/pkdrawing

## Constraints

- Domain must not depend on `PKDrawing`.
- Store metadata separately from drawing data.
- Do not add iCloud, accounts, or sync.
- Use `Application Support/Signotes` for app-owned local data.
- Avoid storing generated PDF exports in MVP persistence.

## Storage Format

- `library.json`
  - Encoded `NoteLibrarySnapshot`.
  - Contains folders, notes, pages, templates, and drawing resource IDs.

- `drawings/<drawingResourceID>.drawing`
  - Raw drawing blob owned by Data layer.
  - Initially produced from `PKDrawing.dataRepresentation()`.

## Interfaces

- `NotesRepository`
  - `loadLibrary() async throws -> NoteLibrarySnapshot`
  - `saveLibrary(_ snapshot: NoteLibrarySnapshot) async throws`

- `DrawingRepository`
  - `loadDrawingData(resourceID: String) async throws -> Data?`
  - `saveDrawingData(_ data: Data, resourceID: String) async throws`

## Tasks

1. Define repository protocols in `Domain/Repositories`.
2. Add filesystem implementations in `Data`.
3. Create directories on first launch.
4. If `library.json` does not exist, write and return the seed snapshot.
5. Use atomic writes for metadata and drawing blobs.
6. Surface corrupt JSON as an error; do not silently overwrite user data.
7. Add lightweight error types for missing root directory, corrupt metadata, and failed writes.

## Acceptance Criteria

- First launch creates a local seed library.
- Existing metadata loads on later launches.
- Drawing data can be saved and loaded by resource ID.
- Corrupt `library.json` produces a visible error path instead of data loss.

## Tests

- Unit test first-load seed creation in a temporary directory.
- Unit test metadata persists across repository instances.
- Unit test drawing blob persists byte-for-byte.
- Unit test corrupt JSON throws a known error.

## Risks

- Autosave can write frequently; keep drawing writes atomic but avoid blocking the main thread.
- Future open file format may need migration. Add a metadata `schemaVersion` field now if implementation starts to need it.

## Definition of Done

- Repositories compile and are covered by unit tests.
- No PencilKit type crosses into Domain.
- Local storage can be deleted and regenerated safely for first-launch seed.

