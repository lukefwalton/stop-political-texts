// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LFWDesignSystem",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "LFWDesignSystem", targets: ["LFWDesignSystem"])
    ],
    targets: [
        .target(name: "LFWDesignSystem"),
        .testTarget(name: "LFWDesignSystemTests", dependencies: ["LFWDesignSystem"])
    ]
)
