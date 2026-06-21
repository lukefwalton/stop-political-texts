import SwiftUI

/// The shared moving-blob background. A `deepSea → ocean` gradient with a
/// few softly blurred color blobs drifting in a slow easeInOut loop. The same
/// motion language across the family makes onboarding flows feel related at
/// a glance, even before the content reads.
public struct LFWOnboardingBackground: View {
    @State private var drift = false

    public init() {}

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [LFWColors.deepSea, LFWColors.ocean],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            blob(LFWColors.nebula.opacity(0.35),   size: 320, x: drift ? -120 : -160, y: drift ? -260 : -315)
            blob(LFWColors.traveler.opacity(0.32), size: 305, x: drift ?  150 :  115, y: drift ?  305 :  350)
            blob(LFWColors.kelp.opacity(0.22),     size: 235, x: drift ? -130 :  -90, y: drift ?  270 :  225)
            blob(LFWColors.gold.opacity(0.14),     size: 225, x: drift ?  145 :  175, y: drift ? -210 : -160)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }

    private func blob(_ color: Color, size: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 80)
            .offset(x: x, y: y)
    }
}
