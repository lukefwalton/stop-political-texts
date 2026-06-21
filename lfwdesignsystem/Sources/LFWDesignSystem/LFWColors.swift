import SwiftUI

/// The shared palette every app in the family draws from. Originally borrowed
/// from a Surmado-era brand standard; carried forward here as the personal
/// "LFW" palette. Plain colors in code — no bundled fonts, logos, or assets.
///
/// Apps are free to declare *additional* accents locally (e.g. Jazz Hands'
/// HUD-only neon set) — but anything that wants to feel like part of the
/// family should reach for these.
public enum LFWColors {
    /// Deep, near-black blue. The bottom of the gradient, the shadow color,
    /// and the contrast text on `paper` button fills.
    public static let deepSea = Color(lfwHex: 0x002A41)

    /// The brand's primary accent — a saturated mid-ocean blue. App-wide tint.
    public static let ocean = Color(lfwHex: 0x1D75BC)

    /// Soft violet for gradient blobs / secondary highlights.
    public static let traveler = Color(lfwHex: 0x6B5AA6)

    /// Hot magenta for gradient blobs.
    public static let nebula = Color(lfwHex: 0x92278F)

    /// Muted seafoam for gradient blobs / "ok" affordances.
    public static let kelp = Color(lfwHex: 0x60C3A3)

    /// The kicker color. Used for eyebrows, hero stroke borders, page dots,
    /// and small icon accents inside cards.
    public static let gold = Color(lfwHex: 0xFFCD34)

    /// Cool slate. Reserved for secondary text/affordances against `paper`.
    public static let steel = Color(lfwHex: 0x3A5068)

    /// The light surface color. Used for headline text on dark backgrounds and
    /// for filled CTA pills.
    public static let paper = Color(lfwHex: 0xEFF9FE)

    /// Very dark blue-black. For surfaces sitting "below" `deepSea`.
    public static let ink = Color(lfwHex: 0x071D2B)

    /// The conventional app-wide tint.
    public static let tint = ocean
}
