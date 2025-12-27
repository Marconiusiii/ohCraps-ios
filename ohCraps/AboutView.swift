import SwiftUI

struct AboutView: View {

	@AccessibilityFocusState private var titleFocused: Bool

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

						Text("Whenever a new strategy is put up on my main Oh Craps website, this app will be updated. This app has been built with a Blind-first accessibility and usability methodology, and supports Dynamic Type and all other assistive technologies on iOS.")
							.font(AppTheme.bodyText)
							.foregroundColor(AppTheme.textPrimary)

						Text("Remember, none of these are guaranteed to make you a winner, as you can never predict how the dice will roll in any given session.")
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

						feedbackButton()

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
		.onAppear {
			DispatchQueue.main.async {
				titleFocused = true
			}
		}
	}

	private func externalLink(title: String, url: String) -> some View {
		Link(title, destination: URL(string: url)!)
			.font(AppTheme.bodyText)
			.foregroundColor(AppTheme.textPrimary)
			.underline()
			.accessibilityHint("Opens in external browser")
	}

	private func feedbackButton() -> some View {
		let subject = "Oh Craps! App Feedback"
			.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

		let mailURL = URL(string: "mailto:marco@marconius.com?subject=\(subject)")!

		return Link("Provide App Feedback", destination: mailURL)
			.font(AppTheme.bodyText)
			.foregroundColor(AppTheme.textPrimary)
			.underline()
			.padding(.vertical, 12)
			.accessibilityHint("Opens Mail to send feedback")
	}

	private var appFooterText: String {
		let version =
			Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"

		let build =
			Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

		return "Oh Craps! by Marco Salsiccia, version \(version), build \(build). © \(Calendar.current.component(.year, from: Date()))"
	}
}
