import Foundation
import PencilKit

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published private(set) var title = "Nota"
    @Published private(set) var page: NotePage?
    @Published var drawing = PKDrawing()
    @Published var errorMessage: String?

    let tool: PKTool = PKInkingTool(.fountainPen, color: .black, width: 2.4)

    private let noteID: UUID
    private let notesRepository: NotesRepository
    private let drawingRepository: DrawingRepository

    init(noteID: UUID, notesRepository: NotesRepository, drawingRepository: DrawingRepository) {
        self.noteID = noteID
        self.notesRepository = notesRepository
        self.drawingRepository = drawingRepository
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
        self.drawing = drawing

        guard let resourceID = page?.drawingResourceID else {
            return
        }

        let data = drawing.dataRepresentation()

        Task {
            do {
                try await drawingRepository.saveDrawingData(data, resourceID: resourceID)
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
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
}
