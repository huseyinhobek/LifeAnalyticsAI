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
            ("OneriHemen", "## Oneri\nHemen")
        ]

        for (source, target) in directFixes {
            text = text.replacingOccurrences(of: source, with: target)
        }

        text = replaceRegex("[-—]{3,}", in: text, with: "\n\n")
        text = replaceRegex("(?<!\\n)(#{1,2}\\s)", in: text, with: "\n$1")
        text = replaceRegex("(?<!\\n)(Hafta:)\\s*", in: text, with: "\n$1 ")
        text = replaceRegex("(?<!\\n)(Ozet:|Gozlem:|Oneri:)\\s*", in: text, with: "\n$1 ")

        text = replaceRegex("(?m)^Ozet:\\s*", in: text, with: "## Ozet\n")
        text = replaceRegex("(?m)^Gozlem:\\s*", in: text, with: "## Gozlem\n")
        text = replaceRegex("(?m)^Oneri:\\s*", in: text, with: "## Oneri\n")

        text = replaceRegex("(?m)^## (Ozet|Gozlem|Oneri)([^\\n])", in: text, with: "## $1\n$2")
        text = replaceRegex("\\n{3,}", in: text, with: "\n\n")
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if !text.lowercased().contains("# haftalik ozet") {
            text = "# Haftalik Ozet\n\n\(text)"
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

    private static func replaceRegex(_ pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: template)
    }
}
