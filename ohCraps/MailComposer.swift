import SwiftUI
import MessageUI

struct MailComposer: UIViewControllerRepresentable {

	let recipient: String
	let subject: String
	let body: String?

	@Environment(\.dismiss)
	private var dismiss

	func makeCoordinator() -> Coordinator {
		Coordinator(dismiss: dismiss)
	}

	func makeUIViewController(context: Context) -> MFMailComposeViewController {
		let controller = MFMailComposeViewController()
		controller.mailComposeDelegate = context.coordinator
		controller.setToRecipients([recipient])
		controller.setSubject(subject)

		if let body = body {
			controller.setMessageBody(body, isHTML: false)
		}

		return controller
	}

	func updateUIViewController(
		_ uiViewController: MFMailComposeViewController,
		context: Context
	) {
	}

	final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

		let dismiss: DismissAction

		init(dismiss: DismissAction) {
			self.dismiss = dismiss
		}

		func mailComposeController(
			_ controller: MFMailComposeViewController,
			didFinishWith result: MFMailComposeResult,
			error: Error?
		) {
			dismiss()
		}
	}
}
