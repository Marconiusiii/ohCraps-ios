import SwiftUI
import UIKit

struct SharePayload: Identifiable {
	let id = UUID()
	let strategyName: String
	let text: String
}

struct ShareSheet: UIViewControllerRepresentable {
	let payload: SharePayload
	let onExportFailure: () -> Void

	init(payload: SharePayload, onExportFailure: @escaping () -> Void = {}) {
		self.payload = payload
		self.onExportFailure = onExportFailure
	}

	func makeCoordinator() -> Coordinator {
		Coordinator()
	}

	func makeUIViewController(context: Context) -> UIActivityViewController {
		let itemSource = StrategyShareItemSource(payload: payload, onExportFailure: onExportFailure)
		context.coordinator.itemSource = itemSource
		let controller = UIActivityViewController(activityItems: [itemSource], applicationActivities: nil)
		controller.completionWithItemsHandler = { _, _, _, _ in
			itemSource.cleanup()
		}
		return controller
	}

	func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
	}

	static func dismantleUIViewController(_ uiViewController: UIActivityViewController, coordinator: Coordinator) {
		coordinator.itemSource?.cleanup()
	}

	final class Coordinator {
		fileprivate var itemSource: StrategyShareItemSource?
	}
}

fileprivate final class StrategyShareItemSource: NSObject, UIActivityItemSource {
	private let payload: SharePayload
	private let onExportFailure: () -> Void
	private var exportFile: StrategyExportFile?
	private var didReportExportFailure = false

	init(payload: SharePayload, onExportFailure: @escaping () -> Void) {
		self.payload = payload
		self.onExportFailure = onExportFailure
	}

	deinit {
		cleanup()
	}

	func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
		payload.text
	}

	func activityViewController(
		_ activityViewController: UIActivityViewController,
		itemForActivityType activityType: UIActivity.ActivityType?
	) -> Any? {
		let filesActivityRawValue = "com.apple.DocumentManagerUICore.SaveToFiles"
		if activityType == .airDrop || activityType == .print || activityType?.rawValue == filesActivityRawValue {
			return exportFileURL()
		}
		return payload.text
	}

	func activityViewController(
		_ activityViewController: UIActivityViewController,
		subjectForActivityType activityType: UIActivity.ActivityType?
	) -> String {
		"Oh Craps! Strategy - \(payload.strategyName)"
	}

	private func exportFileURL() -> URL? {
		if let exportFile {
			return exportFile.url
		}

		do {
			let file = try StrategyExportFile.create(strategyName: payload.strategyName, text: payload.text)
			exportFile = file
			return file.url
		} catch {
			reportExportFailure()
			return nil
		}
	}

	func cleanup() {
		exportFile?.remove()
		exportFile = nil
	}

	private func reportExportFailure() {
		guard !didReportExportFailure else { return }
		didReportExportFailure = true
		DispatchQueue.main.async {
			self.onExportFailure()
		}
	}
}
