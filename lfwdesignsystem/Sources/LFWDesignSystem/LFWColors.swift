import SwiftUI

/// The shared palette every app in the family draws from. Carried forward from
/// an earlier brand standard as the personal "LFW" palette. Plain colors in
/// code — no bundled fonts, logos, or assets. See `STYLE-GUIDE.md` for the
/// full brand spec (colors in priority order, fonts by purpose).
///
/// Brand colors lead with **green** (`forest`/`verdigris`), then **ocean blue**
/// (`ocean`/`deepSea`), then the **ukiyo-e** blue accents. Apps are free to
/// declare *additional* accents locally (e.g. Jazz Hands' HUD-only neon set) —
/// but anything that wants to feel like part of the family should reach for these.
public enum LFWColors {
    // MARK: - Green — the primary brand identity
    //
    // Green leads the brand (see STYLE-GUIDE.md). `forest` is the flagship color,
    // carried over from the lukefwalton.com homepage hero; `verdigris` is the
    // lighter, interactive shade for tints/accents where `forest` is too dark to
    // read. Ocean blue is now the *secondary* family, not the primary.

    /// The flagship brand color — a deep, near-black spruce green. The homepage
    /// hero fill, the deepest surface, the identity anchor.
    public static let forest = Color(lfwHex: 0x1F332B)

    /// The interactive green — a mid verdigris (after *rokushō* 緑青, the ukiyo-e
    /// pigment). Bright enough to read as a tint on dark surfaces, deep enough to
    /// stay tasteful. The app-wide tint and the Forest theme's gradient bottom.
    public static let verdigris = Color(lfwHex: 0x3E8E6E)

    // MARK: - Blue — secondary, one ukiyo-e lineage
    //
    // The blue family is deliberately all woodblock: the deep near-black indigo
    // of `deepSea`, the lifted Prussian "bero-ai" of `ocean` (the blue Hokusai
    // layered over indigo in *The Great Wave*), the mid slate `ukiyoBlue`, and the
    // pale `mist` highlight. No generic web-blue — see STYLE-GUIDE.md.

    /// Deep, near-black indigo. The bottom of the ocean gradient, the shadow
    /// color, and the contrast text on `paper` button fills.
    public static let deepSea = Color(lfwHex: 0x002A41)

    /// The secondary brand accent — a lifted Prussian *bero-ai* (ベロ藍) blue, the
    /// woodblock pigment. Powers the selectable "Deep Sea" theme; no longer the
    /// app-wide default tint.
    public static let ocean = Color(lfwHex: 0x1F5E8C)

    /// The mid woodblock slate blue (matches the site's `--ukiyo-blue`). A serious,
    /// unsaturated accent for links and quiet emphasis on light surfaces.
    public static let ukiyoBlue = Color(lfwHex: 0x245070)

    /// Pale woodblock highlight (the site's `--mist-blue`). Soft borders, hairlines,
    /// and low-emphasis fills.
    public static let mist = Color(lfwHex: 0x7FA8B6)

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

    /// The conventional app-wide tint — now green, leading the brand.
    public static let tint = verdigris

    // MARK: - Semantic status colors
    //
    // The family palette is intentionally cool (blues) with `gold`/`kelp` accents,
    // so apps historically reached for system `.red`/`.orange`/`.green` to signal
    // success/warning/error — which reads off-brand and drifts between apps (one
    // app's "fail" is `.orange`, another's is `.red`). These three tokens give
    // status one shared, on-palette vocabulary, tuned to stay legible as a small
    // icon or label on both a light `paper` surface and a dark themed background.

    /// Positive / success / "done" affordance. A slightly deeper seafoam than
    /// `kelp` so it still holds contrast as text on a light surface.
    public static let success = Color(lfwHex: 0x2E9E74)

    /// Caution / "needs attention" affordance. A warm amber, kept distinct from
    /// the decorative `gold` kicker so warnings don't read as brand furniture.
    public static let warning = Color(lfwHex: 0xE0912F)

    /// Error / destructive / "failed" affordance. A muted rose-red that sits with
    /// the cool palette rather than a pure system red.
    public static let danger = Color(lfwHex: 0xD1495B)
}
