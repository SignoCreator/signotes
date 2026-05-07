import Foundation
import PencilKit

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published private(set) var page: NotePage?
    @Published var drawing = PKDrawing()
    @Published var errorMessage: String?

    let tool: PKTool = PKInkingTool(.fountainPen, color: .black, width: 2.4)

    private let notesRepository: NotesRepository
    private let drawingRepository: DrawingRepository

    init(notesRepository: NotesRepository, drawingRepository: DrawingRepository) {
        self.notesRepository = notesRepository
        self.drawingRepository = drawingRepository
    }

    func load() async {
        do {
            let library = try await notesRepository.loadLibrary()
            guard let firstPage = library.pages.sorted(by: { $0.index < $1.index }).first else {
                return
            }

            page = firstPage

            if let data = try await drawingRepository.loadDrawingData(resourceID: firstPage.drawingResourceID) {
                drawing = try PKDrawing(data: data)
            }
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
}

