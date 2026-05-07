import Foundation

enum LocalStorageError: Error, Equatable {
    case corruptLibrary(URL)
}

