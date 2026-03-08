// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Yap",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Yap",
            path: "Sources",
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"]),
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
            ]
        )
    ]
)
