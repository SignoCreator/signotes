import SwiftUI
import UniformTypeIdentifiers

enum LibraryDragItem: Codable, Hashable, Transferable {
    case folder(UUID)
    case note(UUID)

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .signotesLibraryItem)
    }
}

extension UTType {
    static let signotesLibraryItem = UTType(exportedAs: "com.signocreator.signotes.library-item")
}
