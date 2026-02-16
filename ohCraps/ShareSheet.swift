import SwiftUI
import UIKit

struct SharePayload: Identifiable {
	let id = UUID()
	let strategyName: String
	let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
	let payload: SharePayload

	func makeUIViewController(context: Context) -> UIActivityViewController {
		let itemSource = StrategyShareItemSource(payload: payload)
		return UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
	}

	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
	}
}

private final class StrategyShareItemSource: NSObject, UIActivityItemSource {
	private let payload: SharePayload
	private var cachedAirDropURL: URL?

	init(payload: SharePayload) {
		self.payload = payload
	}

	func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
		payload.text
	}

	func activityViewController(
		_ activityViewController: UIActivityViewController,
		itemForActivityType activityType: UIActivity.ActivityType?
	) -> Any? {
		if activityType == .airDrop {
			return airDropFileURL()
		}
		return payload.text
	}

	func activityViewController(
		_ activityViewController: UIActivityViewController,
		subjectForActivityType activityType: UIActivity.ActivityType?
	) -> String {
		"Oh Craps! Strategy - \(payload.strategyName)"
	}

	private func airDropFileURL() -> URL {
		if let url = cachedAirDropURL {
			return url
		}

		let filename = sanitizedFilename(payload.strategyName) + "_OhCraps.txt"
		let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
		try? payload.text.data(using: .utf8)?.write(to: url, options: .atomic)
		cachedAirDropURL = url
		return url
	}

	private func sanitizedFilename(_ value: String) -> String {
		let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
		let cleaned = value.components(separatedBy: invalid).joined(separator: "_").trimmingCharacters(in: .whitespacesAndNewlines)
		return cleaned.isEmpty ? "Strategy" : cleaned
	}
}
