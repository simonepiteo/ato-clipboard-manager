// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ATOClipboardManager",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ATOClipboardManager", targets: ["ATOClipboardManager"])
    ],
    targets: [
        .executableTarget(
            name: "ATOClipboardManager",
            path: "Sources/ATOClipboardManager"
        ),
        .testTarget(
            name: "ATOClipboardManagerTests",
            dependencies: ["ATOClipboardManager"],
            path: "Tests/ATOClipboardManagerTests"
        )
    ]
)
