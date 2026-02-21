import SwiftUI
import MessageUI

struct AboutView: View {

	@AccessibilityFocusState private var titleFocused: Bool
	@State private var showMail = false
	@Environment(\.openURL)
	private var openURL


	var body: some View {
		ZStack {
			AppTheme.feltGradient
				.ignoresSafeArea()

			VStack(alignment: .leading, spacing: 16) {

				TopNavBar(
					title: "About",
					showBack: false,
					backAction: {}
				)
				.accessibilityFocused($titleFocused)

				ScrollView {
					VStack(alignment: .leading, spacing: 20) {

						Text("Oh Craps! is a collection of Craps strategies I've collected and compiled in one accessible app. Use these when playing my Oh Craps Python game or when you are out and about at a real casino!")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)

						Text("Whenever a new strategy is put up on my main Oh Craps website, this app will be updated. Use the Create Strategy tab to write up and save your own strategies locally to your phone. You can then submit them so everyone who uses this app can check out your strategy!")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)

						Text("Remember, none of these are guaranteed to make you a winner, as you can never predict how the dice will roll in any given session.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)

						Text("This app has been built with a Blind-first accessibility and usability methodology, and supports Dynamic Type and all other assistive technologies on iOS.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)


						Text("References")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityAddTraits(.isHeader)
							.padding(.top, 12)

						Text("These YouTube channels and sites inspired me to learn more about Craps overall and have videos showing most of these strategies in action.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)

						VStack(alignment: .leading, spacing: 12) {

							externalLink(
								title: "Color Up on YouTube",
								url: "https://www.youtube.com/channel/UCPZ2kcfmtAhnf_RVc9fZzNA"
							)

							externalLink(
								title: "Color Up Club",
								url: "https://www.colorup.club"
							)

							externalLink(
								title: "Casino Quest on YouTube",
								url: "https://www.youtube.com/channel/UCpyLp493L8QjrJ4PaL5NOrg"
							)

							externalLink(
								title: "Casino Quest Website",
								url: "https://www.casinoquest.biz"
							)

							externalLink(
								title: "Let It Roll on YouTube",
								url: "https://www.youtube.com/channel/UCe5-Y4pWeudzfeAoaHXT6pA"
							)

							externalLink(
								title: "Craps Hawaii on YouTube",
								url: "https://www.youtube.com/channel/UCsVgwCV1yVN5MbFmdPBGrEA"
							)

							externalLink(
								title: "Vince Armenti on YouTube",
								url: "https://www.youtube.com/channel/UCJx5jilpl2M9dcq0m8tMExQ"
							)

							externalLink(
								title: "Uncle Angelo on YouTube",
								url: "https://www.youtube.com/channel/UCe9uuSMPiwHmhthj1ijQLSA"
							)

							externalLink(
								title: "/r/Craps on Reddit",
								url: "https://www.reddit.com/r/craps/"
							)

							externalLink(
								title: "Square Pair on YouTube",
								url: "https://www.youtube.com/channel/UCXpqqBCl5qOOHOfbHLSZ9og"
							)

							externalLink(
								title: "Oh Craps! Main Website",
								url: "https://marconius.com/craps/"
							)

							externalLink(
								title: "Oh Craps! Game on Github",
								url: "https://github.com/marconiusiii/OhCraps"
							)
						}

						Text("App Credits")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityAddTraits(.isHeader)
							.padding(.top, 12)

						Text("Created by Marco Salsiccia")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)
						Text("Accessibility-First Design and Development")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)
						Text("This app is built and maintained independently as one of my personal passion projects. If you’ve enjoyed using it and would like to support ongoing updates and improvements, you’re welcome to leave a tip. There’s never any obligation.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)
						externalLink(
							title: "Tip the Dealer",
							url: "https://www.paypal.me/marconius"
						)

						Text("Responsible Gambling")
							.font(AppTheme.sectionHeader)
							.foregroundColor(AppTheme.textPrimary)
							.accessibilityAddTraits(.isHeader)
							.padding(.top, 12)
						Text("Gambling should always be approached as entertainment, not as a way to make money. The strategies presented in this app are educational examples only and do not guarantee winnings or reduce the inherent risk involved in casino games.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)

						Text("If gambling ever stops feeling fun, or if you feel pressure to chase losses, it may be a sign to take a break or seek support. Help is available, and reaching out is a positive step.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)
						VStack(alignment: .leading, spacing: 12) {

							externalLink(
								title: "National Problem Gambling Helpline (United States)",
								url: "https://www.ncpgambling.org/help-treatment/"
							)

							externalLink(
								title: "Gamblers Anonymous",
								url: "https://www.gamblersanonymous.org/"
							)

							externalLink(
								title: "International Gambling Support Resources",
								url: "https://www.gamblingtherapy.org/"
							)
						}


						Button {
							if MFMailComposeViewController.canSendMail() {
								showMail = true
							} else {
								openMailFallback()
							}
						} label: {
							Text("Provide App Feedback")
								.font(AppTheme.bodyText)
								.foregroundColor(AppTheme.textPrimary)
						}
						.accessibilityHint("Opens mail composer to send feedback")

						Text(appFooterText)
							.font(AppTheme.metadataText)
							.foregroundColor(AppTheme.textPrimary.opacity(0.75))
							.padding(.top, 24)
					}
					.padding(.horizontal)
					.padding(.bottom, 24)
				}
			}
		}
		.sheet(isPresented: $showMail) {
			MailComposer(
				recipient: "marco@marconius.com",
				subject: "Oh Craps! App Feedback",
				body: nil,
				onFinish: { _ in }
			)
		}
	}

	private func openMailFallback() {
		let subject =
			"Oh Craps! App Feedback"
			.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

		let mailURL =
			URL(string: "mailto:marco@marconius.com?subject=\(subject)")!

		openURL(mailURL)
	}

	private func externalLink(title: String, url: String) -> some View {
		Link(title, destination: URL(string: url)!)
			.font(AppTheme.bodyText)
			.foregroundColor(AppTheme.textPrimary)
			.underline()
			.accessibilityAddTraits(.isLink)
			.accessibilityRemoveTraits(.isButton)
			.accessibilityHint("Opens in external browser")
	}

	private var appFooterText: String {
		let version =
			Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

		let build =
			Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

		return "Oh Craps! version \(version) (\(build)). ©\(Calendar.current.component(.year, from: Date()))"
	}
}
