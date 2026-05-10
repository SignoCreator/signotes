import Foundation
import PencilKit
import UIKit

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published private(set) var title = "Nota"
    @Published private(set) var page: NotePage?
    @Published private(set) var pages: [NotePage] = []
    @Published private(set) var drawing = PKDrawing()
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
    private var pendingDrawing: PKDrawing?
    private var autosaveTask: Task<Void, Never>?
    private var currentPageID: UUID?

    init(
        noteID: UUID,
        notesRepository: NotesRepository,
        drawingRepository: DrawingRepository,
        autosaveDelay: Duration = .milliseconds(700)
    ) {
        self.noteID = noteID
        self.notesRepository = notesRepository
        self.drawingRepository = drawingRepository
        self.autosaveDelay = autosaveDelay
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
            name: "\(preset.name) copia",
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
        guard let pageIndex = currentPageIndex, pageIndex > 0 else {
            return
        }

        await switchToPage(at: pageIndex - 1)
    }

    func goToNextPageOrCreate() async {
        guard let pageIndex = currentPageIndex else {
            return
        }

        if pageIndex < pages.count - 1 {
            await switchToPage(at: pageIndex + 1)
            return
        }

        await appendPageAndSelect()
    }

    private var currentPageIndex: Int? {
        guard let currentPageID else {
            return nil
        }

        return pages.firstIndex { $0.id == currentPageID }
    }

    private func switchToPage(at index: Int) async {
        guard pages.indices.contains(index) else {
            return
        }

        await flushPendingDrawing()

        do {
            let library = try await notesRepository.loadLibrary()
            pages = library.pages(in: noteID)
            guard pages.indices.contains(index) else {
                return
            }

            try await selectPage(pages[index])
        } catch {
            errorMessage = error.localizedDescription
        }
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

    private func selectPage(_ page: NotePage) async throws {
        if let data = try await drawingRepository.loadDrawingData(resourceID: page.drawingResourceID) {
            drawing = try PKDrawing(data: data)
        } else {
            drawing = PKDrawing()
        }

        currentPageID = page.id
        self.page = page
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
