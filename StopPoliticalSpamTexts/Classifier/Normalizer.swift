import Foundation

/// Normalizes message text for matching. Output is transient and never persisted.
enum Normalizer {
    /// Lowercases, folds smart quotes/dashes to ASCII, and collapses whitespace.
    /// Punctuation is preserved so token/phrase boundaries stay meaningful;
    /// boundary-aware matching (see `TermMatcher`) handles the rest.
    static func normalize(_ input: String) -> String {
        var text = input.lowercased()

        let replacements: [Character: Character] = [
            "\u{2018}": "'", // ‘
            "\u{2019}": "'", // ’
            "\u{201B}": "'",
            "\u{201C}": "\"", // “
            "\u{201D}": "\"", // ”
            "\u{2013}": "-", // –
            "\u{2014}": "-", // em dash
            "\u{2212}": "-", // −
            "\u{00A0}": " "  // non-breaking space
        ]
        text = String(text.map { replacements[$0] ?? $0 })

        // Fold diacritics so accent-based evasion (e.g. "dönate") still matches.
        text = text.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US"))

        let collapsed = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
