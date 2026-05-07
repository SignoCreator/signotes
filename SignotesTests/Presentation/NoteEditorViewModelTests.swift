import PencilKit
import XCTest
@testable import Signotes

@MainActor
final class NoteEditorViewModelTests: XCTestCase {
    func testDefaultWritingToolUsesBlackFountainPen() {
        let tool = NoteEditorViewModel.defaultWritingTool()

        XCTAssertEqual(tool.inkType, .fountainPen)
        XCTAssertEqual(tool.color, .black)
        XCTAssertEqual(tool.width, 2.4, accuracy: 0.000_001)
    }

    func testUpdateTemplatePersistsMetadataWithoutSavingDrawingBlob() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = EditorInMemoryDrawingRepository()
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let page = try XCTUnwrap(NoteLibrarySnapshot.seed.firstPage(in: note.id))
        let initialDrawingData = PKDrawing().dataRepresentation()
        await drawingRepository.setData(initialDrawingData, resourceID: page.drawingResourceID)

        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        await viewModel.updateTemplate(.ruled)

        let savedSnapshot = await repository.currentSnapshot()
        let savedPage = try XCTUnwrap(savedSnapshot.firstPage(in: note.id))
        let savedDrawingCount = await drawingRepository.savedDrawingCount()
        let drawingData = try await drawingRepository.loadDrawingData(resourceID: page.drawingResourceID)

        XCTAssertEqual(viewModel.page?.template, .ruled)
        XCTAssertEqual(savedPage.template, .ruled)
        XCTAssertEqual(savedPage.drawingResourceID, page.drawingResourceID)
        XCTAssertEqual(savedDrawingCount, 0)
        XCTAssertEqual(drawingData, initialDrawingData)
    }
}

private actor EditorInMemoryNotesRepository: NotesRepository {
    private var snapshot: NoteLibrarySnapshot

    init(snapshot: NoteLibrarySnapshot) {
        self.snapshot = snapshot
    }

    func loadLibrary() async throws -> NoteLibrarySnapshot {
        snapshot
    }

    func saveLibrary(_ snapshot: NoteLibrarySnapshot) async throws {
        self.snapshot = snapshot
    }

    func currentSnapshot() -> NoteLibrarySnapshot {
        snapshot
    }
}

private actor EditorInMemoryDrawingRepository: DrawingRepository {
    private var dataByResourceID: [String: Data] = [:]
    private var saveCount = 0

    func loadDrawingData(resourceID: String) async throws -> Data? {
        dataByResourceID[resourceID]
    }

    func saveDrawingData(_ data: Data, resourceID: String) async throws {
        dataByResourceID[resourceID] = data
        saveCount += 1
    }

    func deleteDrawingData(resourceID: String) async throws {
        dataByResourceID[resourceID] = nil
    }

    func setData(_ data: Data, resourceID: String) {
        dataByResourceID[resourceID] = data
    }

    func savedDrawingCount() -> Int {
        saveCount
    }
}
