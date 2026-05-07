import XCTest
@testable import Signotes

final class LocalPersistenceTests: XCTestCase {
    private var rootURL: URL!

    override func setUpWithError() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SignotesTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let rootURL, FileManager.default.fileExists(atPath: rootURL.path) {
            try FileManager.default.removeItem(at: rootURL)
        }
    }

    func testLoadLibraryCreatesSeedOnFirstLaunch() async throws {
        let repository = FileSystemNotesRepository(rootURL: rootURL)

        let snapshot = try await repository.loadLibrary()

        XCTAssertEqual(snapshot, .seed)
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("library.json").path))
    }

    func testSaveLibraryPersistsAcrossRepositoryInstances() async throws {
        let firstRepository = FileSystemNotesRepository(rootURL: rootURL)
        var snapshot = NoteLibrarySnapshot.seed
        snapshot.folders[0].name = "Fisica"

        try await firstRepository.saveLibrary(snapshot)

        let secondRepository = FileSystemNotesRepository(rootURL: rootURL)
        let loaded = try await secondRepository.loadLibrary()

        XCTAssertEqual(loaded.folders.first?.name, "Fisica")
    }

    func testDrawingDataRoundTripPreservesBytes() async throws {
        let repository = FileSystemDrawingRepository(rootURL: rootURL)
        let data = Data([0x00, 0x01, 0x02, 0xFE, 0xFF])

        try await repository.saveDrawingData(data, resourceID: "page-1.drawing")

        let loaded = try await repository.loadDrawingData(resourceID: "page-1.drawing")
        XCTAssertEqual(loaded, data)
    }

    func testCorruptLibraryThrowsAndIsNotOverwritten() async throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let libraryURL = rootURL.appendingPathComponent("library.json")
        let corruptData = Data("not json".utf8)
        try corruptData.write(to: libraryURL)

        let repository = FileSystemNotesRepository(rootURL: rootURL)

        do {
            _ = try await repository.loadLibrary()
            XCTFail("Expected corrupt library error")
        } catch let error as LocalStorageError {
            XCTAssertEqual(error, .corruptLibrary(libraryURL))
        }

        XCTAssertEqual(try Data(contentsOf: libraryURL), corruptData)
    }
}

