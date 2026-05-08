import PencilKit
import UIKit
import XCTest
@testable import Signotes

@MainActor
final class NoteEditorViewModelTests: XCTestCase {
    func testDefaultWritingToolUsesBlackFountainPen() {
        let tool = NoteEditorViewModel.defaultWritingTool()

        XCTAssertEqual(tool.inkType, .fountainPen)
        assertBlack(tool.color)
        assertBlack(tool.color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
        XCTAssertEqual(tool.width, 2.4, accuracy: 0.000_001)
    }

    func testEditorToolDefaultsToFountainPen() throws {
        let viewModel = NoteEditorViewModel(
            noteID: UUID(),
            notesRepository: EditorInMemoryNotesRepository(snapshot: .seed),
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        XCTAssertEqual(viewModel.selectedTool, .fountainPen)
        let tool = viewModel.tool as? PKInkingTool
        XCTAssertEqual(tool?.inkType, .fountainPen)
        assertBlack(try XCTUnwrap(tool?.color))
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

    func testSaveIsThrottledUntilFlush() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = EditorInMemoryDrawingRepository()
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let page = try XCTUnwrap(NoteLibrarySnapshot.seed.firstPage(in: note.id))
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        viewModel.save(PKDrawing())

        let saveCountBeforeFlush = await drawingRepository.savedDrawingCount()
        XCTAssertEqual(saveCountBeforeFlush, 0)

        await viewModel.flushPendingDrawing()

        let saveCountAfterFlush = await drawingRepository.savedDrawingCount()
        let savedData = try await drawingRepository.loadDrawingData(resourceID: page.drawingResourceID)
        XCTAssertEqual(saveCountAfterFlush, 1)
        XCTAssertNotNil(savedData)
    }

    func testConsecutiveDrawingChangesFlushOnce() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = EditorInMemoryDrawingRepository()
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        viewModel.save(PKDrawing())
        viewModel.save(PKDrawing())
        viewModel.save(PKDrawing())
        await viewModel.flushPendingDrawing()

        let saveCount = await drawingRepository.savedDrawingCount()
        XCTAssertEqual(saveCount, 1)
    }
}

private func assertBlack(
    _ color: UIColor,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    XCTAssertTrue(
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha),
        file: file,
        line: line
    )
    XCTAssertEqual(red, 0, accuracy: 0.000_001, file: file, line: line)
    XCTAssertEqual(green, 0, accuracy: 0.000_001, file: file, line: line)
    XCTAssertEqual(blue, 0, accuracy: 0.000_001, file: file, line: line)
    XCTAssertEqual(alpha, 1, accuracy: 0.000_001, file: file, line: line)
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
