import Foundation

struct RulesSection: Identifiable {
	let id = UUID()
	let title: String
	let blocks: [RulesBlock]
}

enum RulesBlock {
	case paragraph(String)
	case bulletList([String])
	case subSection(title: String, blocks: [RulesBlock])
}

let rulesContent: [RulesSection] = [

	RulesSection(
		title: "How a Round of Craps Works",
		blocks: [
			.paragraph("Craps is played in rounds. Each round is led by a shooter, who rolls two dice."),
			.paragraph("The first roll of a round is called the come-out roll."),
			.paragraph("If the come-out roll is 7 or 11, Pass Line bets win."),
			.paragraph("If the come-out roll is 2, 3, or 12, Pass Line bets lose."),
			.paragraph("Any other number becomes the point."),
			.paragraph("Once a point is set, the shooter keeps rolling the dice. At this stage, the 2, 3, and 12 no longer affect the Pass Line bet."),
			.paragraph("If the point number is rolled again before a 7, Pass Line bets win and the round ends. The same shooter gets to keep rolling the dice for the next Come Out roll."),
			.paragraph("If a 7 is rolled before the point, this is called a seven out. The round ends, Pass Line bets lose along with Place bets, Come bets, Field bets, and most Proposition bets, and the dice move to the next shooter.")
		]
	),

	RulesSection(
		title: "Table Etiquette",
		blocks: [
			.paragraph("Most casinos expect players to follow a few basic rules of courtesy."),
			.bulletList([
				"Do not touch your chips while the dice are in the air.",
				"Place bets before the shooter rolls. Bets made late may not be accepted.",
				"Dice must hit the back wall of the table. Rolls that do not reach the wall may be called invalid.",
				"Avoid giving betting advice unless someone asks for it.",
				"Respect the shooter and other players at the table.",
				"Try to only cash in before a new round starts, and not during a round currently in session.",
				"Tip your dealers, and don't be afraid to ask them for information about the game or your bets."
			])
		]
	),

	RulesSection(
		title: "Common Terms",
		blocks: [
			.paragraph("Pass Line is a bet that the shooter will win the round by rolling 7 or 11 on the come-out roll, or by making the point before rolling a 7."),
			.paragraph("Don’t Pass is a bet against the shooter. It wins on 2 or 3, loses on 7 or 11, pushes on 12, and wins if a 7 is rolled before the point."),
			.paragraph("Come Bet is a bet made after a point is established. It works like a Pass Line bet, but applies to future rolls."),
			.paragraph("Odds Bet is an additional bet placed behind a Pass Line or Come bet. It pays true odds and has no house edge."),
			.paragraph("Hard Ways numbers are when the 4, 6, 8, or 10 roll with the dice showing double numbers. For example, with both dice showing 2, that is 4 the Hard Way. Rolling a 3 and 1 makes 4 the Easy Way."),
			.paragraph("Seven Out means rolling a 7 after a point is established. This ends the round and the dice move on to the next shooter."),
			.paragraph("Box Numbers refer to the Place Bets, or the 4, 5, 6, 8, 9, and 10 numbers that appear in boxes closest to the dealers on the table surface."),
			.paragraph("Across means placing bets on all of the Place Bet numbers. Inside means placing bets on the 5, 6, 8, and 9. Uptown means the 8, 9, and 10 Place numbers, and Downtown means the 4, 5, and 6."),
			.paragraph("Same Bet means to leave your current bet unchanged. Press means to increase a bet, usually by doubling it. Power Press means adding additional chips from your rack to increase a bet further than just double."),
			.paragraph("Take Down means to remove  a specific bet. Pass Line bets and Come Bets are contract bets that cannot be taken down when the round is in session, but Don't Pass bets can be taken down. Odds, Place, and Lay bets can all be taken down whenever."),
			.paragraph("Working means that bets are On and will count, usually during the Come Out roll. This means that they will lose if a 7 rolls, but will pay if they hit. Alternatively, bets can be turned Off at anytime, meaning that they will not count or be affected until they are turned back On."),
			.paragraph("Parlay means placing all of the winnings of a bet onto the original bet."),
			.paragraph("Two-way means making a bet both for yourself and for the dealers as a means of giving them a tip."),
			.paragraph("High-Low is a Proposition Bet splitting between either the 2 or 12 appearing on the next roll."),
			.paragraph("Yo means Eleven, and is used since Eleven can sound like Seven in a loud casino environment."),
			.paragraph("Coloring Up means exchanging your chips for larger denominations, such as coloring up to a $25 green chip by handing in 5 $5 red chips. Do this if you have an excess of chips in your rack, or when cashing out of the game.")
		]
	),

	RulesSection(
		title: "Typical Payouts",
		blocks: [
			.subSection(
				title: "Pass Line and Come Bets",
				blocks: [
					.paragraph("Pass Line and Come bets usually pay 1 to 1."),
					.paragraph("Don’t Pass and Don’t Come bets also pay 1 to 1 when they win, with a push on 12.")
				]
			),

			.subSection(
				title: "Odds Bets",
				blocks: [
					.paragraph("Odds bets pay true odds. Make these bets by placing the chips directly behind your bet on the Pass Line."),
					.bulletList([
						"On 4 or 10, odds typically pay 2 to 1.",
						"On 5 or 9, odds typically pay 3 to 2.",
						"On 6 or 8, odds typically pay 6 to 5."
					])
				]
			),

			.subSection(
				title: "Place Bets",
				blocks: [
					.paragraph("Place bets are persistent and usually pay less than true odds."),
					.bulletList([
						"On 4 or 10, place bets often pay 9 to 5.",
						"On 5 or 9, they often pay 7 to 5.",
						"On 6 or 8, they often pay 7 to 6."
					]),
					.paragraph("If you Buy a Place Bet, it will pay out at true odds minus a 5 percent commission, often called the vig or the buy. Most casinos will automatically Buy the 4 and 10 for you.")
				]
			),

			.subSection(
				title: "Lay Bets",
				blocks: [
					.paragraph("Lay Bets pay the opposite ratio of the true odds, meaning you risk more to win less."),
					.bulletList([
						"Lay 4 and 10 typically pay 1 to 2.",
						"Lay 5 and 9 typically pay 2 to 3.",
						"Lay 6 and 8 typically pay 5 to 6."
					])
				]
			),

			.subSection(
				title: "Field Bet",
				blocks: [
					.paragraph("Field bets are one-roll bets."),
					.paragraph("The 3, 4, 9, 10, and 11 pay 1 to 1."),
					.paragraph("The numbers 2 or 12 often pay either double or triple, depending on the table.")
				]
			),

			.subSection(
				title: "Proposition Bets",
				blocks: [
					.paragraph("Proposition bets are single-roll bets in the center of the table. Payouts and rules vary by casino and by bet."),
					.bulletList([
						"2 or 12 paying 30 to 1 or 27 to 1.",
						"3 or 11 paying 15 to 1.",
						"Hard 6 and 8 paying 9 to 1.",
						"Hard 4 and 10 paying 7 to 1.",
						"C and E paying 3 to 1."
					]),
					.paragraph("Payouts can vary by casino. Always check the posted table rules and the print on the table felt, and feel free to ask the dealers.")
				]
			)
		]
	)
]
