// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Verbatim",
    platforms: [.macOS("27.0")],
    products: [.executable(name: "Verbatim", targets: ["Verbatim"])],
    targets: [
        .target(name: "TranscriptCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "Verbatim", dependencies: ["TranscriptCore"]),
        .testTarget(name: "TranscriptCoreTests", dependencies: ["TranscriptCore"])
    ]
)
