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

    func testEditorToolStateTracksPreviousSelection() {
        var state = EditorToolState()
        let penID = try! XCTUnwrap(state.presets.first { $0.kind == .pen }?.id)

        state.selectPreset(id: penID)

        XCTAssertEqual(state.selectedPreset.kind, .pen)
        XCTAssertEqual(state.previousPresetID, DrawingToolPreset.defaultFountainPenID)
    }

    func testToolbarPresetsShowSavedPresets() {
        var state = EditorToolState()
        let customPreset = DrawingToolPreset(name: "Custom", kind: .pen, colorHex: "#FF0000", width: 4.0)
        state.syncPresets(DrawingToolPreset.defaults + [customPreset])

        XCTAssertEqual(
            state.toolbarPresets.map(\.kind),
            [.fountainPen, .pen, .pencil, .marker, .eraser, .lasso, .pen]
        )
        XCTAssertEqual(state.toolbarPresets.last?.id, customPreset.id)
    }

    func testToolStateCanDeleteOnlyCustomPresets() {
        var state = EditorToolState()
        let customPreset = DrawingToolPreset(name: "Custom", kind: .pen, colorHex: "#FF0000", width: 4.0)

        state.syncPresets(DrawingToolPreset.defaults + [customPreset])

        XCTAssertFalse(state.canDeletePreset(id: DrawingToolPreset.defaultPenID))
        XCTAssertTrue(state.canDeletePreset(id: customPreset.id))
    }

    func testToolFactoryMapsDefaultPresetsToPencilKitTools() throws {
        for preset in DrawingToolPreset.defaults {
            let tool = EditorToolFactory.makeTool(for: preset)

            switch preset.kind {
            case .fountainPen:
                let inkingTool = try XCTUnwrap(tool as? PKInkingTool)
                XCTAssertEqual(inkingTool.inkType, .fountainPen)
            case .pen:
                let inkingTool = try XCTUnwrap(tool as? PKInkingTool)
                XCTAssertEqual(inkingTool.inkType, .pen)
            case .pencil:
                let inkingTool = try XCTUnwrap(tool as? PKInkingTool)
                XCTAssertEqual(inkingTool.inkType, .pencil)
            case .marker:
                let inkingTool = try XCTUnwrap(tool as? PKInkingTool)
                XCTAssertEqual(inkingTool.inkType, .marker)
            case .eraser:
                XCTAssertTrue(tool is PKEraserTool)
            case .lasso:
                XCTAssertTrue(tool is PKLassoTool)
            }
        }
    }

    func testLoadUsesPersistedToolPresets() async throws {
        var snapshot = NoteLibrarySnapshot.seed
        let customPreset = snapshot.addToolPreset(
            name: "Rosso",
            kind: .pen,
            colorHex: "#FF0000",
            width: 3.3
        )
        let repository = EditorInMemoryNotesRepository(snapshot: snapshot)
        let note = try XCTUnwrap(snapshot.notes.first)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()

        XCTAssertTrue(viewModel.toolState.presets.contains(customPreset))
    }

    func testCreateUpdateAndDeleteToolPresetPersists() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        await viewModel.createToolPreset(name: "Blu", kind: .pen, colorHex: "#007AFF", width: 3.0)

        var savedSnapshot = await repository.currentSnapshot()
        let createdPreset = try XCTUnwrap(savedSnapshot.toolPresets.last)
        XCTAssertEqual(createdPreset.name, "Blu")
        XCTAssertEqual(createdPreset.kind, .pen)
        XCTAssertEqual(createdPreset.colorHex, "#007AFF")
        XCTAssertEqual(createdPreset.width, 3.0)
        XCTAssertEqual(viewModel.toolState.selectedPresetID, createdPreset.id)

        await viewModel.updateToolPreset(
            id: createdPreset.id,
            name: "Verde",
            kind: .fountainPen,
            colorHex: "#34C759",
            width: 4.0
        )

        savedSnapshot = await repository.currentSnapshot()
        XCTAssertEqual(savedSnapshot.toolPreset(id: createdPreset.id)?.name, "Verde")
        XCTAssertEqual(savedSnapshot.toolPreset(id: createdPreset.id)?.kind, .fountainPen)
        XCTAssertEqual(savedSnapshot.toolPreset(id: createdPreset.id)?.colorHex, "#34C759")
        XCTAssertEqual(savedSnapshot.toolPreset(id: createdPreset.id)?.width, 4.0)

        await viewModel.deleteToolPreset(id: createdPreset.id)

        savedSnapshot = await repository.currentSnapshot()
        XCTAssertNil(savedSnapshot.toolPreset(id: createdPreset.id))
        XCTAssertNil(viewModel.toolState.preset(id: createdPreset.id))
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

    func testNextFromLastPageCreatesPageAndFlushesCurrentDrawing() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = EditorInMemoryDrawingRepository()
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let firstPage = try XCTUnwrap(NoteLibrarySnapshot.seed.firstPage(in: note.id))
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        viewModel.save(PKDrawing())
        await viewModel.goToNextPageOrCreate()

        let savedSnapshot = await repository.currentSnapshot()
        let pages = savedSnapshot.pages(in: note.id)
        let firstDrawingData = try await drawingRepository.loadDrawingData(resourceID: firstPage.drawingResourceID)

        XCTAssertEqual(pages.count, 2)
        XCTAssertEqual(viewModel.pages.count, 2)
        XCTAssertEqual(viewModel.page?.id, pages[1].id)
        XCTAssertEqual(viewModel.page?.index, 1)
        XCTAssertEqual(viewModel.page?.template, firstPage.template)
        XCTAssertEqual(viewModel.pageIndicatorText, "2 / 2")
        XCTAssertNotNil(firstDrawingData)
    }

    func testPreviousPageSwitchesBackAfterCreatingSecondPage() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = EditorInMemoryDrawingRepository()
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let firstPage = try XCTUnwrap(NoteLibrarySnapshot.seed.firstPage(in: note.id))
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        await viewModel.goToNextPageOrCreate()
        await viewModel.goToPreviousPage()

        XCTAssertEqual(viewModel.page?.id, firstPage.id)
        XCTAssertEqual(viewModel.pageIndicatorText, "1 / 2")
        XCTAssertFalse(viewModel.canGoToPreviousPage)
    }

    func testTemplateUpdateMutatesOnlyCurrentPage() async throws {
        var snapshot = NoteLibrarySnapshot.seed
        let note = try XCTUnwrap(snapshot.notes.first)
        let firstPage = try XCTUnwrap(snapshot.firstPage(in: note.id))
        let secondPage = try snapshot.appendPage(toNoteID: note.id, template: .grid)
        let repository = EditorInMemoryNotesRepository(snapshot: snapshot)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        await viewModel.goToNextPageOrCreate()
        await viewModel.updateTemplate(.dotted)

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertEqual(savedSnapshot.page(id: firstPage.id)?.template, .grid)
        XCTAssertEqual(savedSnapshot.page(id: secondPage.id)?.template, .dotted)
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
