import XCTest
@testable import ohCraps

final class StrategyExportFileTests: XCTestCase {
	private var temporaryDirectory: URL!

	override func setUpWithError() throws {
		temporaryDirectory = FileManager.default.temporaryDirectory
			.appendingPathComponent("OhCrapsTests-\(UUID().uuidString)", isDirectory: true)
		try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false)
	}

	override func tearDownWithError() throws {
		if let temporaryDirectory {
			try? FileManager.default.removeItem(at: temporaryDirectory)
		}
	}

	func testFilenameRemovesInvalidCharactersAndPreservesSuffix() {
		let filename = StrategyExportFile.filename(for: "My/Unsafe:Strategy?")

		XCTAssertEqual(filename, "My_Unsafe_Strategy__OhCraps.txt")
		XCTAssertFalse(filename.contains("/"))
		XCTAssertFalse(filename.contains(":"))
	}

	func testUnicodeFilenameHonorsUTF8ByteLimit() {
		let filename = StrategyExportFile.filename(for: String(repeating: "🎲", count: 100))

		XCTAssertLessThanOrEqual(filename.utf8.count, StrategyExportFile.maximumFilenameByteCount)
		XCTAssertTrue(filename.hasSuffix(StrategyExportFile.filenameSuffix))
	}

	func testExportUsesUniqueDirectoryAndCleanupRemovesIt() throws {
		let export = try StrategyExportFile.create(
			strategyName: "Test",
			text: "Strategy contents",
			temporaryDirectory: temporaryDirectory
		)
		let parent = export.url.deletingLastPathComponent()

		XCTAssertTrue(FileManager.default.fileExists(atPath: export.url.path))
		XCTAssertTrue(parent.lastPathComponent.hasPrefix(StrategyExportFile.directoryPrefix))

		export.remove()
		XCTAssertFalse(FileManager.default.fileExists(atPath: parent.path))
	}

	func testStaleExportDirectoriesAreRemovedBeforeCreatingNewExport() throws {
		let stale = temporaryDirectory.appendingPathComponent(StrategyExportFile.directoryPrefix + "stale", isDirectory: true)
		try FileManager.default.createDirectory(at: stale, withIntermediateDirectories: false)

		let export = try StrategyExportFile.create(strategyName: "Test", text: "Text", temporaryDirectory: temporaryDirectory)

		XCTAssertFalse(FileManager.default.fileExists(atPath: stale.path))
		export.remove()
	}

	func testExportReportsAnUnusableTemporaryLocation() throws {
		let fileURL = temporaryDirectory.appendingPathComponent("not-a-directory")
		try Data("blocked".utf8).write(to: fileURL)

		XCTAssertThrowsError(
			try StrategyExportFile.create(strategyName: "Test", text: "Text", temporaryDirectory: fileURL)
		)
	}
}
