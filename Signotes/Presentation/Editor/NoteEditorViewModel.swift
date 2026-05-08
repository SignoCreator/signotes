import Foundation
import PencilKit
import UIKit

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published private(set) var title = "Nota"
    @Published private(set) var page: NotePage?
    @Published private(set) var drawing = PKDrawing()
    @Published var selectedTool: EditorDrawingTool = .fountainPen
    @Published var errorMessage: String?

    var tool: any PKTool {
        selectedTool.makeTool()
    }

    private let noteID: UUID
    private let notesRepository: NotesRepository
    private let drawingRepository: DrawingRepository
    private let autosaveDelay: Duration
    private var pendingDrawing: PKDrawing?
    private var autosaveTask: Task<Void, Never>?

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
        PKInkingTool(.fountainPen, color: UIColor.black, width: 2.4)
    }

    func load() async {
        do {
            let library = try await notesRepository.loadLibrary()
            guard let note = library.note(id: noteID), let firstPage = library.firstPage(in: noteID) else {
                return
            }

            title = note.title

            if let data = try await drawingRepository.loadDrawingData(resourceID: firstPage.drawingResourceID) {
                drawing = try PKDrawing(data: data)
            }

            page = firstPage
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

            self.page?.template = template
        } catch {
            errorMessage = error.localizedDescription
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
