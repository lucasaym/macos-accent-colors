// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AccentPicker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "AccentPicker",
            path: "Sources/AccentPicker"
        )
    ]
)
