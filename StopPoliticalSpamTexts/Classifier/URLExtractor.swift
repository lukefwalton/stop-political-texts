import Foundation

/// Hosts pulled from a message. In-memory only; never persisted. Only the host
/// is kept because that is all the classifier consults (domain/shortener match);
/// full URLs are never used.
struct ExtractedURLs: Equatable {
    let hosts: [String]

    func matchesPoliticalDomain() -> Bool {
        hosts.contains { host in
            RuleSet.politicalDomains.contains { Self.host(host, matches: $0) }
        }
    }

    func containsShortener() -> Bool {
        hosts.contains { host in
            RuleSet.urlShorteners.contains { Self.host(host, matches: $0) }
        }
    }

    /// A host matches a domain when it equals it or is a subdomain of it. The
    /// leading-dot suffix check is what keeps `evil-actblue.com` and
    /// `actblue.com.evil.com` from matching `actblue.com`.
    private static func host(_ candidate: String, matches domain: String) -> Bool {
        candidate == domain || candidate.hasSuffix("." + domain)
    }
}

enum URLExtractor {
    /// Matches bare or schemed domains with an optional path. The text is
    /// already normalized (lowercased) before this runs, so the pattern uses
    /// only lowercase classes and no `caseInsensitive` flag is needed.
    private static let domainRegex: NSRegularExpression? = {
        let pattern = "(?:https?://)?([a-z0-9][a-z0-9.-]*\\.[a-z]{2,})(/[^\\s]*)?"
        return try? NSRegularExpression(pattern: pattern, options: [])
    }()

    /// Extracts hosts. No network calls; shorteners are not expanded.
    static func extract(from normalizedText: String) -> ExtractedURLs {
        guard let regex = domainRegex, !normalizedText.isEmpty else {
            return ExtractedURLs(hosts: [])
        }
        let range = NSRange(normalizedText.startIndex..., in: normalizedText)
        var hosts: [String] = []
        regex.enumerateMatches(in: normalizedText, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let hostRange = Range(match.range(at: 1), in: normalizedText) else { return }
            hosts.append(String(normalizedText[hostRange]))
        }
        return ExtractedURLs(hosts: hosts)
    }
}
