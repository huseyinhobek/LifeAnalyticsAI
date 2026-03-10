// MARK: - Core.Utilities

import Foundation

enum WeeklyReportTextFormatter {
    static func normalizedMarkdown(_ raw: String) -> String {
        var text = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return text }

        let directFixes: [(String, String)] = [
            ("Haftalik OzetHafta:", "# Haftalik Ozet\n\nHafta:"),
            ("OzetBu", "## Ozet\nBu"),
            ("GozlemAnomali", "## Gozlem\nAnomali"),
            ("OneriHemen", "## Oneri\nHemen"),
            ("Weekly SummaryWeek:", "# Weekly Summary\n\nWeek:"),
            ("SummaryThis", "## Summary\nThis"),
            ("ObservationAnomaly", "## Observation\nAnomaly"),
            ("RecommendationTry", "## Recommendation\nTry")
        ]

        for (source, target) in directFixes {
            text = text.replacingOccurrences(of: source, with: target)
        }

        let breakTokens = [
            "# ", "## ",
            "Hafta:", "Ozet:", "Gozlem:", "Oneri:",
            "Week:", "Summary:", "Observation:", "Recommendation:"
        ]

        for token in breakTokens {
            text = insertLineBreakBeforeToken(text, token: token)
        }

        let headingRewrites: [(String, String)] = [
            ("Ozet:", "## Ozet"),
            ("Gozlem:", "## Gozlem"),
            ("Oneri:", "## Oneri"),
            ("Summary:", "## Summary"),
            ("Observation:", "## Observation"),
            ("Recommendation:", "## Recommendation")
        ]

        let normalizedLines = text
            .components(separatedBy: .newlines)
            .map { line -> String in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return "" }

                for (source, target) in headingRewrites where trimmed.hasPrefix(source) {
                    let remainder = trimmed.dropFirst(source.count).trimmingCharacters(in: .whitespaces)
                    return remainder.isEmpty ? target : "\(target)\n\(remainder)"
                }

                return trimmed
            }

        text = normalizedLines.joined(separator: "\n")
        text = text.replacingOccurrences(of: "---", with: "\n\n")
        text = text.replacingOccurrences(of: "___", with: "\n\n")
        text = collapseBlankLines(in: text).trimmingCharacters(in: .whitespacesAndNewlines)

        let lower = text.lowercased()
        let hasTRTitle = lower.contains("# haftalik ozet")
        let hasENTitle = lower.contains("# weekly summary")
        if !hasTRTitle && !hasENTitle {
            let shouldPreferEnglish = lower.contains("week:") || lower.contains("summary") || lower.contains("observation") || lower.contains("recommendation")
            let title = shouldPreferEnglish ? "# Weekly Summary" : "# Haftalik Ozet"
            text = "\(title)\n\n\(text)"
        }

        return text
    }

    static func previewText(_ raw: String) -> String {
        var text = normalizedMarkdown(raw)
        text = replaceRegex("(?m)^#{1,6}\\s*", in: text, with: "")
        text = text.replacingOccurrences(of: "**", with: "")
        text = text.replacingOccurrences(of: "*", with: "")
        text = replaceRegex("\\s+", in: text, with: " ")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func insertLineBreakBeforeToken(_ text: String, token: String) -> String {
        guard !token.isEmpty else { return text }
        var output = text
        var searchStart = output.startIndex

        while let range = output.range(of: token, range: searchStart..<output.endIndex) {
            let previous = range.lowerBound > output.startIndex ? output[output.index(before: range.lowerBound)] : "\n"
            if previous != "\n" {
                output.insert("\n", at: range.lowerBound)
                searchStart = output.index(after: range.lowerBound)
            } else {
                searchStart = range.upperBound
            }
        }

        return output
    }

    private static func collapseBlankLines(in text: String) -> String {
        var output = text
        while output.contains("\n\n\n") {
            output = output.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return output
    }

    private static func replaceRegex(_ pattern: String, in text: String, with template: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
        } catch {
            AppLogger.insight.warning("WeeklyReportTextFormatter regex failed: \(error.localizedDescription)")
            return text
        }
    }
}
