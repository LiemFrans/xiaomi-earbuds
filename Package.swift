// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "XiaomiEarbuds",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "XiaomiEarbuds",
            targets: ["XiaomiEarbuds"]
        )
    ],
    targets: [
        .executableTarget(
            name: "XiaomiEarbuds",
            path: "XiaomiEarbuds",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "XiaomiEarbudsTests",
            dependencies: ["XiaomiEarbuds"],
            path: "Tests/XiaomiEarbudsTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                ]),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-framework", "Testing",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                ]),
            ]
        )
    ]
)
