import Foundation
import SwiftUI

@main
struct SignotesApp: App {
    private let rootURL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    )[0].appendingPathComponent("Signotes", isDirectory: true)

    var body: some Scene {
        WindowGroup {
            NoteEditorView(
                viewModel: NoteEditorViewModel(
                    notesRepository: FileSystemNotesRepository(rootURL: rootURL),
                    drawingRepository: FileSystemDrawingRepository(rootURL: rootURL)
                )
            )
        }
    }
}
