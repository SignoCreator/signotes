import Foundation

struct FileSystemDrawingRepository: DrawingRepository {
    private let drawingsURL: URL

    init(rootURL: URL) {
        self.drawingsURL = rootURL.appendingPathComponent("drawings", isDirectory: true)
    }

    func loadDrawingData(resourceID: String) async throws -> Data? {
        let url = drawingURL(resourceID: resourceID)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        return try Data(contentsOf: url)
    }

    func saveDrawingData(_ data: Data, resourceID: String) async throws {
        try ensureDrawingsDirectoryExists()
        try data.write(to: drawingURL(resourceID: resourceID), options: [.atomic])
    }

    private func ensureDrawingsDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: drawingsURL,
            withIntermediateDirectories: true
        )
    }

    private func drawingURL(resourceID: String) -> URL {
        drawingsURL.appendingPathComponent(resourceID)
    }
}

