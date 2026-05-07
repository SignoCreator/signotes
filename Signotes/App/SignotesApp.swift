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
            LibraryView(
                viewModel: LibraryViewModel(
                    notesRepository: FileSystemNotesRepository(rootURL: rootURL),
                    drawingRepository: FileSystemDrawingRepository(rootURL: rootURL)
                ),
                notesRepository: FileSystemNotesRepository(rootURL: rootURL),
                drawingRepository: FileSystemDrawingRepository(rootURL: rootURL)
            )
        }
    }
}
