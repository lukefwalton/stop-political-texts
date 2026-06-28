#if DEBUG
/// DEBUG-only launch-argument routing for App Store screenshot capture.
enum ScreenshotRoute: Hashable {
    case verifyFilter
    case testMessage
    case categories

    static var fromLaunchArguments: ScreenshotRoute? {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-OpenVerifyFilter") { return .verifyFilter }
        if args.contains("-OpenTestMessage") { return .testMessage }
        if args.contains("-OpenCategories") { return .categories }
        return nil
    }
}

/// Signals screenshot capture scripts when the target screen is ready.
enum ScreenshotAutomation {
    private static let readyKey = "ScreenshotReady"

    static func markReady() {
        UserDefaults.standard.set(true, forKey: readyKey)
    }
}
#endif
