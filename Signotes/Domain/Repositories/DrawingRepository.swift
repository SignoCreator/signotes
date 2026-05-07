import Foundation

protocol DrawingRepository: Sendable {
    func loadDrawingData(resourceID: String) async throws -> Data?
    func saveDrawingData(_ data: Data, resourceID: String) async throws
}

