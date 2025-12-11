import Foundation

enum StrategyContentBlock {
	case step(String)        // From <ol><li>
	case bullet(String)      // From nested <ul><li>
	case paragraph(String)   // From <p> (non-metadata)
}

struct StrategyLoader {
	
	static func loadAllStrategies() -> [Strategy] {
		// All .txt files are at the top level of the bundle
		guard let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: nil) else {
			return []
		}
		
		return urls
			.compactMap { loadStrategy(from: $0) }
			.sorted {
				$0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
			}
	}
	
	static func loadStrategy(from url: URL) -> Strategy? {
		guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
			return nil
		}
		
		// Remove any <table> blocks entirely
		let html = removeTables(from: raw)
		
		// NAME
		let name = extractTag("h3", from: html)
		
		// BUY-IN / TABLE MIN / NOTES
		let buyInText = extractValue(
			prefixes: ["Buy-in:", "Buy-In:", "Buy In:"],
			from: html
		)
		
		let tableMinText = extractValue(
			prefixes: ["Table Minimum:", "Table minimum:"],
			from: html
		)
		
		let notes = extractValue(
			prefixes: ["Notes:", "Note:"],
			from: html,
			allowMissing: true
		)
		
		let (buyMin, buyMax) = parseRangeAllowingAny(buyInText)
		let (tableMin, tableMax) = parseRangeAllowingAny(tableMinText)
		
		// BODY CONTENT (OL + nested UL + P)
		let blocks = extractContentBlocks(from: html)
		let flattenedSteps = flattenBlocks(blocks)
		
		return Strategy(
			id: UUID(),
			name: name,
			buyInText: buyInText,
			tableMinText: tableMinText,
			buyInMin: buyMin,
			buyInMax: buyMax,
			tableMinMin: tableMin,
			tableMinMax: tableMax,
			notes: notes,
			steps: flattenedSteps
		)
	}
}

//
// MARK: - Remove tables entirely
//

private func removeTables(from html: String) -> String {
	var output = html
	while let start = output.range(of: "<table", options: .caseInsensitive),
		let end = output.range(of: "</table>", options: .caseInsensitive, range: start.lowerBound..<output.endIndex),
		let close = output.range(of: ">", range: end.lowerBound..<output.endIndex) {
		
		output.removeSubrange(start.lowerBound..<close.upperBound)
	}
	return output
}

//
// MARK: - Metadata extraction
//

private func extractTag(_ tag: String, from html: String) -> String {
	let open = "<\(tag)"
	guard let start = html.range(of: open, options: .caseInsensitive) else {
		return ""
	}
	guard let openEnd = html.range(of: ">", range: start.lowerBound..<html.endIndex) else {
		return ""
	}
	let contentStart = openEnd.upperBound
	
	let close = "</\(tag)>"
	guard let end = html.range(of: close, options: .caseInsensitive, range: contentStart..<html.endIndex) else {
		return ""
	}
	
	let raw = html[contentStart..<end.lowerBound]
	return stripHTML(String(raw)).trimmingCharacters(in: .whitespacesAndNewlines)
}

private func extractValue(
	prefixes: [String],
	from html: String,
	allowMissing: Bool = false
) -> String {
	var searchRange = html.startIndex..<html.endIndex
	
	while let pStart = html.range(of: "<p", options: .caseInsensitive, range: searchRange) {
		guard let openEnd = html.range(of: ">", range: pStart.lowerBound..<html.endIndex) else {
			break
		}
		let contentStart = openEnd.upperBound
		
		guard let pEnd = html.range(of: "</p>", options: .caseInsensitive, range: contentStart..<html.endIndex) else {
			break
		}
		
		let inner = String(html[contentStart..<pEnd.lowerBound])
		let text = stripHTML(inner).trimmingCharacters(in: .whitespacesAndNewlines)
		
		for prefix in prefixes {
			if text.lowercased().hasPrefix(prefix.lowercased()) {
				let value = text.dropFirst(prefix.count)
				return value.trimmingCharacters(in: .whitespacesAndNewlines)
			}
		}
		
		searchRange = pEnd.upperBound..<html.endIndex
	}
	
	return allowMissing ? "" : "Unknown"
}

//
// MARK: - Body parsing (OL + nested UL + P) with hierarchy preserved
//

private struct PositionedBlock {
	let position: Int
	let block: StrategyContentBlock
}

private func extractContentBlocks(from html: String) -> [StrategyContentBlock] {
	var records: [PositionedBlock] = []
	let startIndex = html.startIndex
	let endIndex = html.endIndex
	
	// ----------- Ordered lists <ol> (steps) -----------
	var searchRange = startIndex..<endIndex
	
	while let olStart = html.range(of: "<ol", options: .caseInsensitive, range: searchRange) {
		guard let openEnd = html.range(of: ">", range: olStart.lowerBound..<endIndex) else {
			break
		}
		let listContentStart = openEnd.upperBound
		
		guard let olEnd = html.range(of: "</ol>", options: .caseInsensitive, range: listContentStart..<endIndex) else {
			break
		}
		
		let listPos = html.distance(from: startIndex, to: olStart.lowerBound)
		let listContent = html[listContentStart..<olEnd.lowerBound]
		
		var liSearch = listContent.startIndex..<listContent.endIndex
		
		while let liStart = listContent.range(of: "<li", options: .caseInsensitive, range: liSearch) {
			guard let liOpenEnd = listContent.range(of: ">", range: liStart.lowerBound..<listContent.endIndex) else {
				break
			}
			let liContentStart = liOpenEnd.upperBound
			
			guard let liEnd = listContent.range(of: "</li>", options: .caseInsensitive, range: liContentStart..<listContent.endIndex) else {
				break
			}
			
			let liInner = listContent[liContentStart..<liEnd.lowerBound]
			let liString = String(liInner)
			
			// Check for nested <ul ...> inside this <li>
			if let ulStart = liString.range(of: "<ul", options: .caseInsensitive),
				let ulOpenEnd = liString.range(of: ">", range: ulStart.lowerBound..<liString.endIndex),
				let ulEnd = liString.range(of: "</ul>", options: .caseInsensitive, range: ulOpenEnd.upperBound..<liString.endIndex) {
				
				// Main step text (before nested UL)
				let mainPart = String(liString[..<ulStart.lowerBound])
				let mainText = stripHTML(mainPart).trimmingCharacters(in: .whitespacesAndNewlines)
				if !mainText.isEmpty {
					records.append(
						PositionedBlock(
							position: listPos,
							block: .step(mainText)
						)
					)
				}
				
				// Nested bullets from the UL
				let ulContent = liString[ulOpenEnd.upperBound..<ulEnd.lowerBound]
				var bulletSearch = ulContent.startIndex..<ulContent.endIndex
				
				while let bLiStart = ulContent.range(of: "<li", options: .caseInsensitive, range: bulletSearch) {
					guard let bOpenEnd = ulContent.range(of: ">", range: bLiStart.lowerBound..<ulContent.endIndex) else {
						break
					}
					let bContentStart = bOpenEnd.upperBound
					
					guard let bLiEnd = ulContent.range(of: "</li>", options: .caseInsensitive, range: bContentStart..<ulContent.endIndex) else {
						break
					}
					
					let bInner = ulContent[bContentStart..<bLiEnd.lowerBound]
					let bText = stripHTML(String(bInner)).trimmingCharacters(in: .whitespacesAndNewlines)
					
					if !bText.isEmpty {
						records.append(
							PositionedBlock(
								position: listPos,
								block: .bullet(bText)
							)
						)
					}
					
					bulletSearch = bLiEnd.upperBound..<ulContent.endIndex
				}
				
			} else {
				// Simple <li> with no nested UL
				let stepText = stripHTML(liString).trimmingCharacters(in: .whitespacesAndNewlines)
				if !stepText.isEmpty {
					records.append(
						PositionedBlock(
							position: listPos,
							block: .step(stepText)
						)
					)
				}
			}
			
			liSearch = liEnd.upperBound..<listContent.endIndex
		}
		
		searchRange = olEnd.upperBound..<endIndex
	}
	
	// ----------- Paragraphs <p> (non-metadata) -----------
	var pSearch = startIndex..<endIndex
	
	while let pStart = html.range(of: "<p", options: .caseInsensitive, range: pSearch) {
		guard let pOpenEnd = html.range(of: ">", range: pStart.lowerBound..<endIndex) else {
			break
		}
		let pContentStart = pOpenEnd.upperBound
		
		guard let pEnd = html.range(of: "</p>", options: .caseInsensitive, range: pContentStart..<endIndex) else {
			break
		}
		
		let pInner = html[pContentStart..<pEnd.lowerBound]
		let pText = stripHTML(String(pInner)).trimmingCharacters(in: .whitespacesAndNewlines)
		
		if !pText.isEmpty {
			let lower = pText.lowercased()
			let isMeta = lower.hasPrefix("buy-in")
				|| lower.hasPrefix("buy in")
				|| lower.hasPrefix("table minimum")
				|| lower.hasPrefix("notes")
				|| lower.hasPrefix("note")
			
			if !isMeta {
				let pos = html.distance(from: startIndex, to: pStart.lowerBound)
				records.append(
					PositionedBlock(
						position: pos,
						block: .paragraph(pText)
					)
				)
			}
		}
		
		pSearch = pEnd.upperBound..<endIndex
	}
	
	// Sort by position so <p>, OL, nested UL all appear in reading order
	let sorted = records.sorted { $0.position < $1.position }
	return sorted.map { $0.block }
}

//
// MARK: - Strip HTML tags
//

private func stripHTML(_ s: String) -> String {
	var result = ""
	var insideTag = false
	
	for ch in s {
		if ch == "<" {
			insideTag = true
			continue
		}
		if ch == ">" {
			insideTag = false
			continue
		}
		if !insideTag {
			result.append(ch)
		}
	}
	
	return result
		.replacingOccurrences(of: "&nbsp;", with: " ")
		.replacingOccurrences(of: "&amp;", with: "&")
}

//
// MARK: - Range parsing with "Any"
//

private func parseRangeAllowingAny(_ text: String) -> (Int, Int) {
	let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
	let lower = trimmed.lowercased()
	
	if lower == "any" {
		return (0, Int.max)
	}
	
	let cleaned = trimmed.replacingOccurrences(of: "$", with: "")
	
	if cleaned.contains("-") {
		let parts = cleaned.split(separator: "-")
		let minVal = Int(parts[0].trimmingCharacters(in: .whitespaces)) ?? 0
		let maxVal = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
		return (minVal, maxVal)
	}
	
	let value = Int(cleaned) ?? 0
	return (value, value)
}

//
// MARK: - Flatten blocks to steps array
//

private func flattenBlocks(_ blocks: [StrategyContentBlock]) -> [String] {
	var steps: [String] = []
	
	for block in blocks {
		switch block {
		case .step(let text):
			// Ordered step. UI will add "1.", "2.", etc.
			steps.append(text)
			
		case .bullet(let text):
			// Bullet supporting info. Keep bullet marker here.
			steps.append("• \(text)")
			
		case .paragraph(let text):
			steps.append(text)
		}
	}
	
	return steps
}
