import Foundation

/// The two text views term matching runs against.
///
/// `text` is the canonical normalized body. URL extraction and the critical
/// allowlist (including the auth-code regex) read ONLY this view, so hosts and
/// one-time codes are never corrupted by de-obfuscation. `deobfuscated` is
/// non-nil only when `Deobfuscator` actually changed something, so clean
/// messages — the overwhelming majority — pay for zero extra regex work.
struct MatchableText: Equatable {
    let text: String
    let deobfuscated: String?
}

/// Reverses in-word obfuscation that survives `Normalizer` — the tricks
/// spammers use to break term matching without hurting readability:
/// punctuation-stuffed and spaced-out letters ("d.o.n.a.t.e", "d o n a t e"),
/// repeated characters ("dooonate"), and leetspeak ("d0nate").
///
/// Everything here produces a *matching-only* view. It is intentionally lossy
/// ("www" collapses to "w") and must never feed URL extraction, the auth-code
/// regex, or anything user-visible. Pure logic, no I/O — safe to ship in the
/// extension.
enum Deobfuscator {

    static func matchable(_ normalizedText: String) -> MatchableText {
        MatchableText(text: normalizedText, deobfuscated: deobfuscate(normalizedText))
    }

    /// A de-obfuscated copy of already-normalized text, or nil when no
    /// transform changed anything. Passes run in this order so stuffed
    /// letters are joined before repeat-collapse and leet folding see them.
    static func deobfuscate(_ normalized: String) -> String? {
        var text = collapseStuffedLetters(normalized)
        text = collapseRepeatedRuns(text)
        text = foldLeet(text)
        return text == normalized ? nil : text
    }

    // MARK: - Stuffed / spaced letters

    /// Separators spammers stuff between letters. One run must use a single,
    /// identical separator throughout ("d.o-n.a.t.e" does not collapse).
    private static let stuffingSeparators: Set<Character> = [".", "-", "*", "_", "+", " "]

    /// Minimum letters before a run collapses. Four keeps real abbreviations
    /// ("F Y I", "e.g.", "V.I.P.") intact while catching "v o t e" and longer.
    private static let minimumStuffedLetters = 4

    /// Joins maximal `letter sep letter sep letter…` runs of single letters:
    /// "d.o.n.a.t.e" → "donate", "d o n a t e" → "donate". Each letter in the
    /// run must stand alone (its other neighbor is not a letter), so the run
    /// ends before an ordinary word: "d o n a t e now" keeps " now".
    private static func collapseStuffedLetters(_ text: String) -> String {
        let chars = Array(text)
        var out = ""
        out.reserveCapacity(chars.count)
        var i = 0
        while i < chars.count {
            let char = chars[i]
            if isAsciiLetter(char),
               i == 0 || !isAsciiLetter(chars[i - 1]),
               i + 1 < chars.count,
               stuffingSeparators.contains(chars[i + 1]) {
                let separator = chars[i + 1]
                var letters = [char]
                var j = i + 1
                while j + 1 < chars.count,
                      chars[j] == separator,
                      isAsciiLetter(chars[j + 1]),
                      j + 2 >= chars.count || !isAsciiLetter(chars[j + 2]) {
                    letters.append(chars[j + 1])
                    j += 2
                }
                if letters.count >= minimumStuffedLetters {
                    out.append(contentsOf: letters)
                    i = j
                    continue
                }
            }
            out.append(char)
            i += 1
        }
        return out
    }

    // MARK: - Repeated characters

    /// Letter runs of 3+ collapse to one ("dooonate" → "donate"). Letters
    /// only, so "123456" and "!!!" are untouched. English doubles survive;
    /// "www" becomes "w" in this view only, which is inert — URL extraction
    /// never reads it and no rule term is "w".
    private static let repeatedRunRegex = try? NSRegularExpression(pattern: "([a-z])\\1{2,}")

    private static func collapseRepeatedRuns(_ text: String) -> String {
        guard let regex = repeatedRunRegex else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1")
    }

    // MARK: - Leetspeak

    private static let leetMap: [Character: Character] = [
        "0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "7": "t",
        "@": "a", "$": "s", "!": "i"
    ]

    /// Folds leet substitutions, but only for characters whose immediate
    /// neighbors are both letters, inside runs that contain at least two
    /// letters. That keeps every digit that isn't visually impersonating a
    /// letter intact:
    ///   "d0nate"   → "donate"     (0 between letters)
    ///   "123456"   unchanged      (no letters in the run)
    ///   "maga2026" unchanged      (0 flanked by digits — the auth-code regex
    ///                              and MAGA-style codes keep their digits)
    ///   "stop2end" unchanged      (2 is not in the map)
    /// Trailing/leading leet ("don8", "$5") is deliberately not folded — the
    /// eval corpus measures whether that gap ever matters.
    private static func foldLeet(_ text: String) -> String {
        var chars = Array(text)
        var i = 0
        while i < chars.count {
            guard isRunCharacter(chars[i]) else {
                i += 1
                continue
            }
            var j = i
            while j < chars.count, isRunCharacter(chars[j]) { j += 1 }
            let run = Array(chars[i..<j])
            let letterCount = run.reduce(0) { $0 + (isAsciiLetter($1) ? 1 : 0) }
            if letterCount >= 2, run.count >= 3 {
                // Neighbor checks read the original run, not partial folds,
                // so the pass is order-independent.
                for k in 1..<(run.count - 1) {
                    if let folded = leetMap[run[k]],
                       isAsciiLetter(run[k - 1]),
                       isAsciiLetter(run[k + 1]) {
                        chars[i + k] = folded
                    }
                }
            }
            i = j
        }
        return String(chars)
    }

    private static func isRunCharacter(_ char: Character) -> Bool {
        isAsciiLetter(char) || ("0"..."9").contains(char)
            || char == "@" || char == "$" || char == "!"
    }

    private static func isAsciiLetter(_ char: Character) -> Bool {
        ("a"..."z").contains(char)
    }
}

extension TermMatcher {
    /// Boundary-aware match against the canonical view, falling back to the
    /// de-obfuscated view when one exists.
    static func matches(term: String, in views: MatchableText) -> Bool {
        if matches(term: term, in: views.text) { return true }
        guard let deobfuscated = views.deobfuscated else { return false }
        return matches(term: term, in: deobfuscated)
    }
}

extension Rule {
    /// True if any term matches either view.
    func matches(_ views: MatchableText) -> Bool {
        terms.contains { TermMatcher.matches(term: $0, in: views) }
    }
}
