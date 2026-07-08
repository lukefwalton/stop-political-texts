import Foundation

/// Normalizes message text for matching. Output is transient and never persisted.
enum Normalizer {

    /// Lowercase Cyrillic/Greek characters that render like Latin letters and
    /// get substituted into Latin words to dodge term matching ("dоnate" with
    /// a Cyrillic о). A bounded, auditable map — deliberately not a full
    /// Unicode confusables table (iOS exposes no public ICU confusables API).
    /// Applied after lowercasing, so only lowercase forms are listed.
    private static let homoglyphs: [Character: Character] = [
        // Cyrillic
        "\u{0430}": "a", // а
        "\u{0435}": "e", // е
        "\u{043E}": "o", // о
        "\u{0440}": "p", // р
        "\u{0441}": "c", // с
        "\u{0443}": "y", // у
        "\u{0445}": "x", // х
        "\u{0456}": "i", // і
        "\u{0455}": "s", // ѕ
        "\u{0458}": "j", // ј
        "\u{0501}": "d", // ԁ
        "\u{0475}": "v", // ѵ
        "\u{051B}": "q", // ԛ
        "\u{051D}": "w", // ԝ
        // Greek
        "\u{03BF}": "o", // ο
        "\u{03B1}": "a", // α
        "\u{03BD}": "v", // ν
        "\u{03B9}": "i", // ι
        "\u{03BA}": "k", // κ
        "\u{03C4}": "t", // τ
        "\u{03C5}": "u", // υ
        "\u{03C1}": "p"  // ρ
    ]

    /// Strips invisible format characters, lowercases, folds smart
    /// quotes/dashes and homoglyphs to ASCII, folds diacritics and width, and
    /// collapses whitespace. Punctuation is preserved so token/phrase
    /// boundaries stay meaningful; boundary-aware matching (see `TermMatcher`)
    /// handles the rest. In-word obfuscation that survives normalization
    /// (leetspeak, stuffed letters) is `Deobfuscator`'s job.
    static func normalize(_ input: String) -> String {
        // Drop format characters (Unicode category Cf): zero-width
        // space/joiner/non-joiner, BOM, word joiner, soft hyphen, directional
        // marks. They render as nothing — "do\u{200B}nate" reads as "donate" —
        // but break term matching if kept.
        var scalars = String.UnicodeScalarView()
        for scalar in input.unicodeScalars where scalar.properties.generalCategory != .format {
            scalars.append(scalar)
        }

        var text = String(scalars).lowercased()

        var replacements: [Character: Character] = [
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
        replacements.merge(homoglyphs) { current, _ in current }
        text = String(text.map { replacements[$0] ?? $0 })

        // Fold diacritics so accent-based evasion (e.g. "dönate") still
        // matches, and width so fullwidth forms (ｄｏｎａｔｅ) do too.
        text = text.folding(
            options: [.diacriticInsensitive, .widthInsensitive],
            locale: Locale(identifier: "en_US")
        )

        let collapsed = text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
