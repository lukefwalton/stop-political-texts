import SwiftUI

public extension Color {
    /// Build a `Color` from a packed 24-bit RGB hex literal (e.g. `0x1D75BC`).
    /// Used throughout the design system so palette colors stay legible in code.
    init(lfwHex hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
