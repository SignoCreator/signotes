import Combine
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

    func testGoToPageSelectsExplicitExistingPageWithoutAppending() async throws {
        var snapshot = NoteLibrarySnapshot.seed
        let note = try XCTUnwrap(snapshot.notes.first)
        let firstPage = try XCTUnwrap(snapshot.firstPage(in: note.id))
        let secondPage = try snapshot.appendPage(toNoteID: note.id, template: .dotted)
        let repository = EditorInMemoryNotesRepository(snapshot: snapshot)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        await viewModel.goToPage(id: secondPage.id)

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertEqual(viewModel.page?.id, secondPage.id)
        XCTAssertEqual(viewModel.previousPage?.id, firstPage.id)
        XCTAssertEqual(savedSnapshot.pages(in: note.id).count, 2)
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

    func testInsertPageBeforeSelectsAndPersistsNewPage() async throws {
        var snapshot = NoteLibrarySnapshot.seed
        let note = try XCTUnwrap(snapshot.notes.first)
        let firstPage = try XCTUnwrap(snapshot.firstPage(in: note.id))
        let secondPage = try snapshot.appendPage(toNoteID: note.id, template: .ruled)
        let repository = EditorInMemoryNotesRepository(snapshot: snapshot)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        await viewModel.insertPage(before: secondPage.id)

        let savedSnapshot = await repository.currentSnapshot()
        let orderedPages = savedSnapshot.pages(in: note.id)
        XCTAssertEqual(orderedPages.count, 3)
        XCTAssertEqual(orderedPages.map(\.id).first, firstPage.id)
        XCTAssertEqual(orderedPages.map(\.id).last, secondPage.id)
        XCTAssertEqual(viewModel.page?.id, orderedPages[1].id)
        XCTAssertEqual(viewModel.pageIndicatorText, "2 / 3")
    }

    func testDuplicatePageCopiesDrawingDataAndSelectsDuplicate() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let drawingRepository = EditorInMemoryDrawingRepository()
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let firstPage = try XCTUnwrap(NoteLibrarySnapshot.seed.firstPage(in: note.id))
        let sourceData = PKDrawing().dataRepresentation()
        await drawingRepository.setData(sourceData, resourceID: firstPage.drawingResourceID)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        await viewModel.duplicatePage(after: firstPage.id)

        let savedSnapshot = await repository.currentSnapshot()
        let duplicate = try XCTUnwrap(savedSnapshot.pages(in: note.id).last)
        let duplicatedData = try await drawingRepository.loadDrawingData(resourceID: duplicate.drawingResourceID)
        XCTAssertNotEqual(duplicate.id, firstPage.id)
        XCTAssertNotEqual(duplicate.drawingResourceID, firstPage.drawingResourceID)
        XCTAssertEqual(duplicatedData, sourceData)
        XCTAssertEqual(viewModel.page?.id, duplicate.id)
    }

    func testDeleteCurrentPageDeletesDrawingDataAndSelectsNearestPage() async throws {
        var snapshot = NoteLibrarySnapshot.seed
        let note = try XCTUnwrap(snapshot.notes.first)
        let firstPage = try XCTUnwrap(snapshot.firstPage(in: note.id))
        let secondPage = try snapshot.appendPage(toNoteID: note.id, template: .ruled)
        let thirdPage = try snapshot.appendPage(toNoteID: note.id, template: .dotted)
        let repository = EditorInMemoryNotesRepository(snapshot: snapshot)
        let drawingRepository = EditorInMemoryDrawingRepository()
        await drawingRepository.setData(PKDrawing().dataRepresentation(), resourceID: secondPage.drawingResourceID)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: drawingRepository
        )

        await viewModel.load()
        await viewModel.goToPage(id: secondPage.id)
        await viewModel.deletePage(id: secondPage.id)

        let savedSnapshot = await repository.currentSnapshot()
        let deletedData = try await drawingRepository.loadDrawingData(resourceID: secondPage.drawingResourceID)
        XCTAssertEqual(savedSnapshot.pages(in: note.id).map(\.id), [firstPage.id, thirdPage.id])
        XCTAssertNil(deletedData)
        XCTAssertEqual(viewModel.page?.id, thirdPage.id)
        XCTAssertEqual(viewModel.pageIndicatorText, "2 / 2")
    }

    func testDeleteOnlyPageIsRejectedByViewModel() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let page = try XCTUnwrap(NoteLibrarySnapshot.seed.firstPage(in: note.id))
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        await viewModel.deletePage(id: page.id)

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertEqual(savedSnapshot.pages(in: note.id).count, 1)
        XCTAssertEqual(viewModel.page?.id, page.id)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testMovePagePersistsOrderAndKeepsCurrentSelection() async throws {
        var snapshot = NoteLibrarySnapshot.seed
        let note = try XCTUnwrap(snapshot.notes.first)
        let firstPage = try XCTUnwrap(snapshot.firstPage(in: note.id))
        let secondPage = try snapshot.appendPage(toNoteID: note.id, template: .ruled)
        let thirdPage = try snapshot.appendPage(toNoteID: note.id, template: .dotted)
        let repository = EditorInMemoryNotesRepository(snapshot: snapshot)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        await viewModel.goToPage(id: secondPage.id)
        await viewModel.movePage(id: thirdPage.id, toIndex: 0)

        let savedSnapshot = await repository.currentSnapshot()
        XCTAssertEqual(savedSnapshot.pages(in: note.id).map(\.id), [thirdPage.id, firstPage.id, secondPage.id])
        XCTAssertEqual(viewModel.pages.map(\.id), [thirdPage.id, firstPage.id, secondPage.id])
        XCTAssertEqual(viewModel.page?.id, secondPage.id)
        XCTAssertEqual(viewModel.pageIndicatorText, "3 / 3")
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

    func testSaveUpdatesPreviewRevisionWithoutPublishingEditorState() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository()
        )

        await viewModel.load()
        let page = try XCTUnwrap(viewModel.page)
        var publishCount = 0
        let cancellable = viewModel.objectWillChange.sink {
            publishCount += 1
        }

        XCTAssertEqual(viewModel.previewRevision(for: page), 0)

        viewModel.save(PKDrawing())
        viewModel.save(PKDrawing())

        XCTAssertEqual(viewModel.previewRevision(for: page), 2)
        XCTAssertEqual(publishCount, 0)
        withExtendedLifetime(cancellable) {}
    }

    func testSavePublishesThrottledPreviewRefreshOnlyWhenOverviewIsVisible() async throws {
        let repository = EditorInMemoryNotesRepository(snapshot: .seed)
        let note = try XCTUnwrap(NoteLibrarySnapshot.seed.notes.first)
        let viewModel = NoteEditorViewModel(
            noteID: note.id,
            notesRepository: repository,
            drawingRepository: EditorInMemoryDrawingRepository(),
            autosaveDelay: .seconds(60),
            pageOverviewPreviewRefreshDelay: .milliseconds(10)
        )

        await viewModel.load()
        let initialGeneration = viewModel.pageOverviewPreviewGeneration

        viewModel.save(PKDrawing())
        try await Task.sleep(for: .milliseconds(25))
        XCTAssertEqual(viewModel.pageOverviewPreviewGeneration, initialGeneration)

        viewModel.setPageOverviewPresented(true)
        viewModel.save(PKDrawing())
        XCTAssertEqual(viewModel.pageOverviewPreviewGeneration, initialGeneration)
        try await Task.sleep(for: .milliseconds(25))
        XCTAssertEqual(viewModel.pageOverviewPreviewGeneration, initialGeneration + 1)

        viewModel.setPageOverviewPresented(false)
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

    func testPreviewImageCacheReusesSameKeyAndRegeneratesOnRevisionTemplateSizeOrScaleChange() {
        let cache = EditorPagePreviewImageCache(countLimit: 8)
        let pageID = UUID()
        let baseKey = EditorPagePreviewImageKey(
            pageID: pageID,
            template: .grid,
            drawingRevision: 0,
            pageSize: CGSize(width: 794, height: 1123),
            screenScale: 2
        )
        var renderCount = 0

        let firstImage = cache.image(for: baseKey) {
            renderCount += 1
            return UIImage()
        }
        let cachedImage = cache.image(for: baseKey) {
            renderCount += 1
            return UIImage()
        }

        XCTAssertTrue(firstImage === cachedImage)
        XCTAssertEqual(renderCount, 1)

        _ = cache.image(
            for: EditorPagePreviewImageKey(
                pageID: pageID,
                template: .grid,
                drawingRevision: 1,
                pageSize: CGSize(width: 794, height: 1123),
                screenScale: 2
            )
        ) {
            renderCount += 1
            return UIImage()
        }
        _ = cache.image(
            for: EditorPagePreviewImageKey(
                pageID: pageID,
                template: .ruled,
                drawingRevision: 0,
                pageSize: CGSize(width: 794, height: 1123),
                screenScale: 2
            )
        ) {
            renderCount += 1
            return UIImage()
        }
        _ = cache.image(
            for: EditorPagePreviewImageKey(
                pageID: pageID,
                template: .grid,
                drawingRevision: 0,
                pageSize: CGSize(width: 600, height: 900),
                screenScale: 2
            )
        ) {
            renderCount += 1
            return UIImage()
        }
        _ = cache.image(
            for: EditorPagePreviewImageKey(
                pageID: pageID,
                template: .grid,
                drawingRevision: 0,
                pageSize: CGSize(width: 794, height: 1123),
                screenScale: 3
            )
        ) {
            renderCount += 1
            return UIImage()
        }

        XCTAssertEqual(renderCount, 5)
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
