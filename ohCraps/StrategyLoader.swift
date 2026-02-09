import Foundation

enum StrategyContentBlock {
	case step(String)
	case bullet(String)
	case paragraph(String)
	case heading(String)
}

struct StrategyLoader {
	
	static func loadAllStrategies() -> [Strategy] {
		guard let urls = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: nil) else {
			return []
		}
		
		return urls
			.compactMap { loadStrategy(from: $0) }
			.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
	}
	
	static func loadStrategy(fromHTML html: String) -> Strategy? {

		// NAME
		let name = extractTag("h3", from: html)

		// METADATA
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

		let credit = extractValue(
			prefixes: ["Credit:", "Credits:"],
			from: html,
			allowMissing: true
		)

		let (buyMin, buyMax) = parseRangeAllowingAny(buyInText)
		let (tMin, tMax) = parseRangeAllowingAny(tableMinText)

		let contentBlocks = extractContentBlocks(from: html)
		let flattened = flattenBlocks(contentBlocks)

		return Strategy(
			id: UUID(),
			name: name,
			buyInText: buyInText,
			tableMinText: tableMinText,
			buyInMin: buyMin,
			buyInMax: buyMax,
			tableMinMin: tMin,
			tableMinMax: tMax,
			notes: notes,
			credit: credit,
			steps: flattened
		)
	}

	static func loadStrategy(from url: URL) -> Strategy? {
		guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
			return nil
		}
		
		let html = raw
		
		// NAME
		let name = extractTag("h3", from: html)
		
		// METADATA PARAGRAPHS
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
		
		let credit = extractValue(
			prefixes: ["Credit:", "Credits:"],
			from: html,
			allowMissing: true
		)

		
		let (buyMin, buyMax) = parseRangeAllowingAny(buyInText)
		let (tMin, tMax) = parseRangeAllowingAny(tableMinText)
		
		// BODY CONTENT (OL / UL / H4 / P)
		let contentBlocks = extractContentBlocks(from: html)
		let flattened = flattenBlocks(contentBlocks)
		
		return Strategy(
			id: UUID(),
			name: name,
			buyInText: buyInText,
			tableMinText: tableMinText,
			buyInMin: buyMin,
			buyInMax: buyMax,
			tableMinMin: tMin,
			tableMinMax: tMax,
			notes: notes,
			credit: credit,
			steps: flattened
		)
	}
}

//
// MARK: - Basic HTML helpers
//

private func stripHTML(_ s: String) -> String {
	var result = ""
	var inside = false
	
	for ch in s {
		if ch == "<" {
			inside = true
			continue
		}
		if ch == ">" {
			inside = false
			continue
		}
		if !inside {
			result.append(ch)
		}
	}
	
	return result
		.replacingOccurrences(of: "&nbsp;", with: " ")
		.replacingOccurrences(of: "&amp;", with: "&")
		.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func replaceWithSpaces(_ range: Range<String.Index>, in string: inout String) {
	let length = string.distance(from: range.lowerBound, to: range.upperBound)
	let spaces = String(repeating: " ", count: length)
	string.replaceSubrange(range, with: spaces)
}

//
// MARK: - Tag extraction (h3)
//

private func extractTag(_ tag: String, from html: String) -> String {
	let open = "<\(tag)"
	guard let start = html.range(of: open, options: .caseInsensitive) else { return "" }
	guard let openEnd = html.range(of: ">", range: start.lowerBound..<html.endIndex) else { return "" }
	let contentStart = openEnd.upperBound
	
	let close = "</\(tag)>"
	guard let end = html.range(of: close, options: .caseInsensitive, range: contentStart..<html.endIndex) else { return "" }
	
	let raw = String(html[contentStart..<end.lowerBound])
	return stripHTML(raw)
}

//
// MARK: - Metadata paragraphs (Buy-in, Table Minimum, Notes)
//

private func extractValue(
	prefixes: [String],
	from html: String,
	allowMissing: Bool = false
) -> String {
	var searchRange = html.startIndex..<html.endIndex
	
	while let pStart = html.range(of: "<p", options: .caseInsensitive, range: searchRange) {
		guard let openEnd = html.range(of: ">", range: pStart.lowerBound..<html.endIndex) else { break }
		let contentStart = openEnd.upperBound
		
		guard let pEnd = html.range(of: "</p>", options: .caseInsensitive, range: contentStart..<html.endIndex) else { break }
		
		let inner = String(html[contentStart..<pEnd.lowerBound])
		let text = stripHTML(inner)
		let lower = text.lowercased()
		
		for prefix in prefixes {
			if lower.hasPrefix(prefix.lowercased()) {
				let valueStart = text.index(text.startIndex, offsetBy: prefix.count)
				let value = text[valueStart...].trimmingCharacters(in: .whitespacesAndNewlines)
				return value
			}
		}
		
		searchRange = pEnd.upperBound..<html.endIndex
	}
	
	return allowMissing ? "" : "Unknown"
}

//
// MARK: - Content block extraction
//
// This function is the heart of the parser. It:
//
//	1. Removes tables entirely (replaced with spaces).
//	2. Blanks out Buy-in / Table Minimum / Notes paragraphs from the working string.
//	3. Extracts UL bullets, replacing the UL segments with spaces.
//	4. Extracts OL steps from the “UL-stripped” string.
//	5. Extracts h4 headings.
//	6. Extracts remaining paragraphs (non-metadata).
//	7. Sorts everything by position in the original text.
//

private func extractContentBlocks(from html: String) -> [StrategyContentBlock] {
	let original = html
	var work = html
	
	// 1) Remove tables, preserving length
	while let tableStart = work.range(of: "<table", options: .caseInsensitive) {
		guard let tableEnd = work.range(of: "</table>", options: .caseInsensitive, range: tableStart.lowerBound..<work.endIndex) else {
			break
		}
		let fullRange = tableStart.lowerBound..<tableEnd.upperBound
		replaceWithSpaces(fullRange, in: &work)
	}
	
	// 2) Blank metadata paragraphs (Buy-in, Table Minimum, Notes)
	func blankMetaParagraphs(prefixes: [String]) {
		var searchRange = work.startIndex..<work.endIndex
		
		while let pStart = work.range(of: "<p", options: .caseInsensitive, range: searchRange) {
			guard let openEnd = work.range(of: ">", range: pStart.lowerBound..<work.endIndex) else { break }
			let contentStart = openEnd.upperBound
			
			guard let pEnd = work.range(of: "</p>", options: .caseInsensitive, range: contentStart..<work.endIndex) else { break }
			
			let innerOriginal = String(original[contentStart..<pEnd.lowerBound])
			let text = stripHTML(innerOriginal)
			let lower = text.lowercased()
			
			let isMeta = prefixes.contains { prefix in
				lower.hasPrefix(prefix.lowercased())
			}
			
			if isMeta {
				let fullRange = pStart.lowerBound..<pEnd.upperBound
				replaceWithSpaces(fullRange, in: &work)
				searchRange = fullRange.upperBound..<work.endIndex
			} else {
				searchRange = pEnd.upperBound..<work.endIndex
			}
		}
	}
	
	blankMetaParagraphs(prefixes: [
		"buy-in:",
		"buy in:",
		"table minimum:",
		"notes:",
		"note:",
		"Credit:",
		"Credits:"
	])
	
	// Storage with positions
	var positioned: [(pos: Int, block: StrategyContentBlock)] = []
	
	// Helper: distance in original
	func position(for index: String.Index) -> Int {
		return original.distance(from: original.startIndex, to: index)
	}
	
	// 3) UL bullets: parse from 'work', grab LI text from 'original', then blank UL section
	var searchRange = work.startIndex..<work.endIndex
	
	while let ulStart = work.range(of: "<ul", options: .caseInsensitive, range: searchRange) {
		guard let ulEndTag = work.range(of: "</ul>", options: .caseInsensitive, range: ulStart.lowerBound..<work.endIndex) else { break }
		guard let ulTagClose = work.range(of: ">", range: ulStart.lowerBound..<ulEndTag.upperBound) else { break }
		
		let ulOpenEnd = ulTagClose.upperBound
		let ulCloseStart = ulEndTag.lowerBound
		
		let ulStartIndex = ulStart.lowerBound
		
		// Map inner UL to original for clean text
		let ulInnerOriginal = original[ulOpenEnd..<ulCloseStart]
		var ulInner = String(ulInnerOriginal)
		
		var innerSearch = ulInner.startIndex..<ulInner.endIndex
		
		while let liStart = ulInner.range(of: "<li", options: .caseInsensitive, range: innerSearch) {
			guard let liTagClose = ulInner.range(of: ">", range: liStart.lowerBound..<ulInner.endIndex) else { break }
			let liContentStart = liTagClose.upperBound
			
			guard let liEndTag = ulInner.range(of: "</li>", options: .caseInsensitive, range: liContentStart..<ulInner.endIndex) else { break }
			let liContentEnd = liEndTag.lowerBound
			
			let liInner = String(ulInner[liContentStart..<liContentEnd])
			let text = stripHTML(liInner)
			
			if !text.isEmpty {
				let pos = position(for: ulStartIndex)
				positioned.append((pos: pos, block: .bullet(text)))
			}
			
			innerSearch = liEndTag.upperBound..<ulInner.endIndex
		}
		
		let fullRange = ulStartIndex..<ulEndTag.upperBound
		replaceWithSpaces(fullRange, in: &work)
		searchRange = fullRange.upperBound..<work.endIndex
	}
	
	// 4) OL steps: now work has ULs blanked out, so <li> inside <ol> are clean steps
	searchRange = work.startIndex..<work.endIndex
	
	while let olStart = work.range(of: "<ol", options: .caseInsensitive, range: searchRange) {
		guard let olEndTag = work.range(of: "</ol>", options: .caseInsensitive, range: olStart.lowerBound..<work.endIndex) else { break }
		guard let olTagClose = work.range(of: ">", range: olStart.lowerBound..<olEndTag.upperBound) else { break }
		
		let listStart = olTagClose.upperBound
		let listEnd = olEndTag.lowerBound
		
		var listSearch = listStart..<listEnd
		
		while let liStart = work.range(of: "<li", options: .caseInsensitive, range: listSearch) {
			guard liStart.lowerBound < listEnd else { break }
			
			guard let liTagClose = work.range(of: ">", range: liStart.lowerBound..<listEnd) else { break }
			let liContentStart = liTagClose.upperBound
			
			guard let liEndTag = work.range(of: "</li>", options: .caseInsensitive, range: liContentStart..<listEnd) else { break }
			let liContentEnd = liEndTag.lowerBound
			
			let liInnerSlice = work[liContentStart..<liContentEnd]
			let text = stripHTML(String(liInnerSlice))
			
			if !text.isEmpty {
				let pos = position(for: liStart.lowerBound)
				positioned.append((pos: pos, block: .step(text)))
			}
			
			listSearch = liEndTag.upperBound..<listEnd
		}
		
		searchRange = olEndTag.upperBound..<work.endIndex
	}
	
	// 5) H4 headings
	searchRange = work.startIndex..<work.endIndex
	
	while let hStart = work.range(of: "<h4", options: .caseInsensitive, range: searchRange) {
		guard let tagClose = work.range(of: ">", range: hStart.lowerBound..<work.endIndex) else { break }
		let contentStart = tagClose.upperBound
		
		guard let endTag = work.range(of: "</h4>", options: .caseInsensitive, range: contentStart..<work.endIndex) else { break }
		let contentEnd = endTag.lowerBound
		
		let headingText = stripHTML(String(original[contentStart..<contentEnd]))
		
		if !headingText.isEmpty {
			let pos = position(for: hStart.lowerBound)
			positioned.append((pos: pos, block: .heading(headingText)))
		}
		
		searchRange = endTag.upperBound..<work.endIndex
	}
	
	// 6) Remaining paragraphs (non-metadata, since metadata areas were blanked out)
	searchRange = work.startIndex..<work.endIndex
	
	while let pStart = work.range(of: "<p", options: .caseInsensitive, range: searchRange) {
		guard let tagClose = work.range(of: ">", range: pStart.lowerBound..<work.endIndex) else { break }
		let contentStart = tagClose.upperBound
		
		guard let pEndTag = work.range(of: "</p>", options: .caseInsensitive, range: contentStart..<work.endIndex) else { break }
		let contentEnd = pEndTag.lowerBound
		
		let paragraphText = stripHTML(String(original[contentStart..<contentEnd]))
		
		if !paragraphText.isEmpty {
			let pos = position(for: pStart.lowerBound)
			positioned.append((pos: pos, block: .paragraph(paragraphText)))
		}
		
		searchRange = pEndTag.upperBound..<work.endIndex
	}
	
	// 7) Sort by original position and return blocks
	let sorted = positioned.sorted { $0.pos < $1.pos }
	return sorted.map { $0.block }
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
	
	let value = Int(cleaned.trimmingCharacters(in: .whitespaces)) ?? 0
	return (value, value)
}

//
// MARK: - Flatten blocks into tagged strings
//

private func flattenBlocks(_ blocks: [StrategyContentBlock]) -> [String] {
	var result: [String] = []
	
	for block in blocks {
		switch block {
		case .step(let text):
			result.append("§STEP§" + text)
			
		case .bullet(let text):
			result.append("§BULLET§" + text)
			
		case .paragraph(let text):
			result.append("§PARA§" + text)
			
		case .heading(let text):
			result.append("§H4§" + text)
		}
	}
	
	return result
}
