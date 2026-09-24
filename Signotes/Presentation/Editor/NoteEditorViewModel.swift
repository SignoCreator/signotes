import Foundation
import PencilKit
import UIKit

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published private(set) var title = "Note"
    @Published private(set) var page: NotePage?
    @Published private(set) var pages: [NotePage] = []
    @Published private(set) var drawing = PKDrawing()
    @Published private(set) var pageOverviewPreviewGeneration = 0
    @Published var toolState = EditorToolState()
    @Published var errorMessage: String?

    var pageIndicatorText: String {
        guard let pageIndex = currentPageIndex else {
            return "0 / 0"
        }

        return "\(pageIndex + 1) / \(max(pages.count, 1))"
    }

    var canGoToPreviousPage: Bool {
        guard let pageIndex = currentPageIndex else {
            return false
        }

        return pageIndex > 0
    }

    var previousPage: NotePage? {
        guard let pageIndex = currentPageIndex, pageIndex > 0 else {
            return nil
        }

        return pages[pageIndex - 1]
    }

    var nextPage: NotePage? {
        guard let pageIndex = currentPageIndex, pageIndex < pages.count - 1 else {
            return nil
        }

        return pages[pageIndex + 1]
    }

    var tool: any PKTool {
        EditorToolFactory.makeTool(for: toolState.selectedPreset)
    }

    var selectedTool: EditorDrawingTool {
        get {
            EditorDrawingTool(kind: toolState.selectedPreset.kind)
        }
        set {
            toolState.selectToolKind(newValue.kind)
        }
    }

    private let noteID: UUID
    private let notesRepository: NotesRepository
    private let drawingRepository: DrawingRepository
    private let autosaveDelay: Duration
    private let pageOverviewPreviewRefreshDelay: Duration
    private var pendingDrawing: PKDrawing?
    private var autosaveTask: Task<Void, Never>?
    private var pageOverviewPreviewRefreshTask: Task<Void, Never>?
    private var currentPageID: UUID?
    private var isPageOverviewPresented = false
    private var previewStates: [UUID: PagePreviewState] = [:]

    init(
        noteID: UUID,
        notesRepository: NotesRepository,
        drawingRepository: DrawingRepository,
        autosaveDelay: Duration = .milliseconds(700),
        pageOverviewPreviewRefreshDelay: Duration = .milliseconds(250)
    ) {
        self.noteID = noteID
        self.notesRepository = notesRepository
        self.drawingRepository = drawingRepository
        self.autosaveDelay = autosaveDelay
        self.pageOverviewPreviewRefreshDelay = pageOverviewPreviewRefreshDelay
    }

    static func defaultWritingTool() -> PKInkingTool {
        guard let tool = EditorToolFactory.makeTool(for: DrawingToolPreset.defaultFountainPen) as? PKInkingTool else {
            preconditionFailure("Default fountain pen preset must map to PKInkingTool.")
        }

        return tool
    }

    func load() async {
        do {
            let library = try await notesRepository.loadLibrary()
            guard let note = library.note(id: noteID), let firstPage = library.firstPage(in: noteID) else {
                return
            }

            toolState.syncPresets(library.toolPresets)
            title = note.title
            pages = library.pages(in: noteID)
            try await selectPage(firstPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(_ drawing: PKDrawing) {
        pendingDrawing = drawing
        if let page {
            cachePreviewDrawing(drawing, for: page.id, incrementRevision: true)
        }
        schedulePageOverviewPreviewRefreshIfNeeded()
        scheduleAutosave()
    }

    func selectTool(_ tool: EditorDrawingTool) {
        selectedTool = tool
    }

    func createToolPreset(name: String, kind: DrawingToolKind, colorHex: String, width: Double) async {
        do {
            var library = try await notesRepository.loadLibrary()
            let preset = library.addToolPreset(name: name, kind: kind, colorHex: colorHex, width: width)
            try await notesRepository.saveLibrary(library)

            toolState.syncPresets(library.toolPresets)
            toolState.selectPreset(id: preset.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateToolPreset(id: UUID, name: String, kind: DrawingToolKind, colorHex: String, width: Double) async {
        do {
            var library = try await notesRepository.loadLibrary()
            try library.updateToolPreset(id: id, name: name, kind: kind, colorHex: colorHex, width: width)
            try await notesRepository.saveLibrary(library)

            toolState.syncPresets(library.toolPresets)
            toolState.selectPreset(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateToolPreset(id: UUID) async {
        guard let preset = toolState.preset(id: id) else {
            return
        }

        await createToolPreset(
            name: "\(preset.name) copy",
            kind: preset.kind,
            colorHex: preset.colorHex,
            width: preset.width
        )
    }

    func deleteToolPreset(id: UUID) async {
        do {
            var library = try await notesRepository.loadLibrary()
            try library.deleteCustomToolPreset(id: id)
            try await notesRepository.saveLibrary(library)

            toolState.syncPresets(library.toolPresets)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func flushPendingDrawing() async {
        autosaveTask?.cancel()
        autosaveTask = nil

        guard let pendingDrawing, let resourceID = page?.drawingResourceID else {
            return
        }

        self.pendingDrawing = nil
        let data = pendingDrawing.dataRepresentation()

        do {
            try await drawingRepository.saveDrawingData(data, resourceID: resourceID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTemplate(_ template: PageTemplate) async {
        guard let page else {
            return
        }

        do {
            var library = try await notesRepository.loadLibrary()
            try library.updatePageTemplate(pageID: page.id, template: template)
            try await notesRepository.saveLibrary(library)

            pages = library.pages(in: noteID)
            self.page?.template = template
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goToPreviousPage() async {
        guard let previousPage else {
            return
        }

        await goToPage(id: previousPage.id)
    }

    func goToPage(id pageID: UUID) async {
        await flushPendingDrawing()

        do {
            let library = try await notesRepository.loadLibrary()
            pages = library.pages(in: noteID)
            guard let page = pages.first(where: { $0.id == pageID }) else {
                return
            }

            try await selectPage(page)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func appendPageAfterCurrent() async {
        await appendPageAndSelect()
    }

    func appendPageAtEnd() async {
        await flushPendingDrawing()

        do {
            var library = try await notesRepository.loadLibrary()
            let newPage = try library.appendPage(toNoteID: noteID, template: page?.template ?? .grid)
            try await notesRepository.saveLibrary(library)

            pages = library.pages(in: noteID)
            try await selectPage(newPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func insertPage(before pageID: UUID) async {
        await insertPageAndSelect { library in
            try library.insertPage(before: pageID)
        }
    }

    func insertPage(after pageID: UUID) async {
        await insertPageAndSelect { library in
            try library.insertPage(after: pageID)
        }
    }

    func duplicatePage(after pageID: UUID) async {
        await flushPendingDrawing()

        do {
            var library = try await notesRepository.loadLibrary()
            guard let sourcePage = library.page(id: pageID) else {
                throw LibraryMutationError.pageNotFound(pageID)
            }

            let duplicatedPage = try library.duplicatePage(after: pageID)
            if let sourceData = try await drawingRepository.loadDrawingData(resourceID: sourcePage.drawingResourceID) {
                try await drawingRepository.saveDrawingData(sourceData, resourceID: duplicatedPage.drawingResourceID)
            }

            try await notesRepository.saveLibrary(library)
            pages = library.pages(in: noteID)
            try await selectPage(duplicatedPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePage(id pageID: UUID) async {
        await flushPendingDrawing()

        do {
            var library = try await notesRepository.loadLibrary()
            let deletion = try library.deletePage(id: pageID)
            try await notesRepository.saveLibrary(library)
            do {
                try await drawingRepository.deleteDrawingData(resourceID: deletion.drawingResourceID)
            } catch {
                errorMessage = error.localizedDescription
            }

            let selectedPageID = currentPageID == pageID ? deletion.preferredSelectionPageID : currentPageID
            previewStates[pageID] = nil
            pages = library.pages(in: noteID)

            if let selectedPageID, let selectedPage = pages.first(where: { $0.id == selectedPageID }) {
                try await selectPage(selectedPage)
            } else if let firstPage = pages.first {
                try await selectPage(firstPage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func movePage(id pageID: UUID, toIndex targetIndex: Int) async {
        await flushPendingDrawing()

        do {
            var library = try await notesRepository.loadLibrary()
            try library.movePage(id: pageID, toIndex: targetIndex)
            try await notesRepository.saveLibrary(library)

            pages = library.pages(in: noteID)
            if let currentPageID, let currentPage = pages.first(where: { $0.id == currentPageID }) {
                page = currentPage
            }
            await loadAdjacentPreviewDrawings()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goToNextPageOrCreate() async {
        guard let pageIndex = currentPageIndex else {
            return
        }

        if pageIndex < pages.count - 1 {
            await goToPage(id: pages[pageIndex + 1].id)
            return
        }

        await appendPageAfterCurrent()
    }

    func previewDrawing(for page: NotePage?) -> PKDrawing {
        guard let page else {
            return PKDrawing()
        }

        return previewStates[page.id]?.drawing ?? PKDrawing()
    }

    func previewRevision(for page: NotePage?) -> Int {
        guard let page else {
            return 0
        }

        return previewStates[page.id]?.revision ?? 0
    }

    func loadPageOverviewPreviews() async {
        await flushPendingDrawing()
        await loadPreviewDrawings(for: pages, reloadExisting: true, incrementRevision: true)
        pageOverviewPreviewGeneration += 1
    }

    func setPageOverviewPresented(_ isPresented: Bool) {
        isPageOverviewPresented = isPresented

        if !isPresented {
            pageOverviewPreviewRefreshTask?.cancel()
            pageOverviewPreviewRefreshTask = nil
        }
    }

    private var currentPageIndex: Int? {
        guard let currentPageID else {
            return nil
        }

        return pages.firstIndex { $0.id == currentPageID }
    }

    private func appendPageAndSelect() async {
        await flushPendingDrawing()

        do {
            var library = try await notesRepository.loadLibrary()
            let template = page?.template ?? .grid
            let newPage = try library.appendPage(toNoteID: noteID, template: template)
            try await notesRepository.saveLibrary(library)

            pages = library.pages(in: noteID)
            try await selectPage(newPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func insertPageAndSelect(_ mutation: (inout NoteLibrarySnapshot) throws -> NotePage) async {
        await flushPendingDrawing()

        do {
            var library = try await notesRepository.loadLibrary()
            let newPage = try mutation(&library)
            try await notesRepository.saveLibrary(library)

            pages = library.pages(in: noteID)
            try await selectPage(newPage)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func selectPage(_ page: NotePage) async throws {
        if let data = try await drawingRepository.loadDrawingData(resourceID: page.drawingResourceID) {
            drawing = try PKDrawing(data: data)
        } else {
            drawing = PKDrawing()
        }

        cachePreviewDrawing(drawing, for: page.id, incrementRevision: false)
        currentPageID = page.id
        self.page = page
        await loadAdjacentPreviewDrawings()
    }

    private func loadAdjacentPreviewDrawings() async {
        await loadPreviewDrawings(for: [previousPage, nextPage].compactMap(\.self))
    }

    private func loadPreviewDrawings(
        for pages: [NotePage],
        reloadExisting: Bool = false,
        incrementRevision: Bool = false
    ) async {
        for page in pages where reloadExisting || previewStates[page.id] == nil {
            do {
                if let data = try await drawingRepository.loadDrawingData(resourceID: page.drawingResourceID) {
                    cachePreviewDrawing(try PKDrawing(data: data), for: page.id, incrementRevision: incrementRevision)
                } else {
                    cachePreviewDrawing(PKDrawing(), for: page.id, incrementRevision: incrementRevision)
                }
            } catch {
                cachePreviewDrawing(PKDrawing(), for: page.id, incrementRevision: incrementRevision)
            }
        }
    }

    private func cachePreviewDrawing(_ drawing: PKDrawing, for pageID: UUID, incrementRevision: Bool) {
        let currentRevision = previewStates[pageID]?.revision ?? 0
        previewStates[pageID] = PagePreviewState(
            drawing: drawing,
            revision: incrementRevision ? currentRevision + 1 : currentRevision
        )
    }

    private func schedulePageOverviewPreviewRefreshIfNeeded() {
        guard isPageOverviewPresented else {
            return
        }

        pageOverviewPreviewRefreshTask?.cancel()
        pageOverviewPreviewRefreshTask = Task { [weak self, pageOverviewPreviewRefreshDelay] in
            do {
                try await Task.sleep(for: pageOverviewPreviewRefreshDelay)
            } catch {
                return
            }

            guard let self, !Task.isCancelled, self.isPageOverviewPresented else {
                return
            }

            self.pageOverviewPreviewGeneration += 1
        }
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self, autosaveDelay] in
            do {
                try await Task.sleep(for: autosaveDelay)
            } catch {
                return
            }

            await self?.flushPendingDrawing()
        }
    }
}

private struct PagePreviewState {
    let drawing: PKDrawing
    let revision: Int
}
