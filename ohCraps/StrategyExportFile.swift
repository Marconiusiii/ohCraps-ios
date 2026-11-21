import Foundation

struct StrategyExportFile {
	static let directoryPrefix = "OhCrapsShare-"
	static let filenameSuffix = "_OhCraps.txt"
	static let maximumFilenameByteCount = 120

	let url: URL
	private let directoryURL: URL
	private let fileManager: FileManager

	static func create(
		strategyName: String,
		text: String,
		fileManager: FileManager = .default,
		temporaryDirectory: URL? = nil
	) throws -> StrategyExportFile {
		let root = temporaryDirectory ?? fileManager.temporaryDirectory
		try removeStaleExports(fileManager: fileManager, temporaryDirectory: root)

		let directory = root.appendingPathComponent(directoryPrefix + UUID().uuidString, isDirectory: true)
		try fileManager.createDirectory(at: directory, withIntermediateDirectories: false)

		let fileURL = directory.appendingPathComponent(filename(for: strategyName), isDirectory: false)
		do {
			guard let data = text.data(using: .utf8) else {
				throw CocoaError(.fileWriteInapplicableStringEncoding)
			}
			try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
			return StrategyExportFile(url: fileURL, directoryURL: directory, fileManager: fileManager)
		} catch {
			try? fileManager.removeItem(at: directory)
			throw error
		}
	}

	func remove() {
		try? fileManager.removeItem(at: directoryURL)
	}

	static func filename(for strategyName: String) -> String {
		let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
			.union(.controlCharacters)
		let replaced = strategyName.components(separatedBy: invalid).joined(separator: "_")
		let cleaned = replaced.trimmingCharacters(in: .whitespacesAndNewlines)
		let base = cleaned.isEmpty ? "Strategy" : cleaned
		let availableBytes = maximumFilenameByteCount - filenameSuffix.utf8.count

		var limited = ""
		for character in base {
			let candidate = limited + String(character)
			guard candidate.utf8.count <= availableBytes else { break }
			limited = candidate
		}

		if limited.isEmpty {
			limited = "Strategy"
		}
		return limited + filenameSuffix
	}

	static func removeStaleExports(
		fileManager: FileManager = .default,
		temporaryDirectory: URL? = nil
	) throws {
		let root = temporaryDirectory ?? fileManager.temporaryDirectory
		let contents = try fileManager.contentsOfDirectory(
			at: root,
			includingPropertiesForKeys: nil,
			options: [.skipsHiddenFiles]
		)
		for url in contents where url.lastPathComponent.hasPrefix(directoryPrefix) {
			try? fileManager.removeItem(at: url)
		}
	}
}
