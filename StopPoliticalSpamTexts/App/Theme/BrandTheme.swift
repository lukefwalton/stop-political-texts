import SwiftUI
import LFWDesignSystem

/// App-side alias for the shared family palette. Every color here forwards to
/// `LFWDesignSystem.LFWColors` so this app stays in lockstep with the other
/// apps in the family; only add a new key here if it's genuinely
/// political-spam-app-specific.
///
/// Compiled into the `StopPoliticalSpamTexts` app target only — the
/// `StopPoliticalSpamTextsMessageFilter` extension's `sources:` are
/// `StopPoliticalSpamTextsMessageFilter` + `StopPoliticalSpamTexts/Classifier`
/// + `StopPoliticalSpamTexts/Storage`, none of which contain `App/`, so the
/// extension never sees this file or its `import LFWDesignSystem`.
enum BrandColor {
    static let ocean = LFWColors.ocean
    static let deepSea = LFWColors.deepSea
    static let traveler = LFWColors.traveler
    static let nebula = LFWColors.nebula
    static let gold = LFWColors.gold
    static let kelp = LFWColors.kelp
    static let steel = LFWColors.steel
    static let paper = LFWColors.paper
}
