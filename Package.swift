// swift-tools-version:5.9
// TweetFlow Pro - Twitter/X Content Creation & Management for macOS

import PackageDescription

let package = Package(
    name: "TweetFlowPro",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "TweetFlowPro", targets: ["TweetFlowPro"])
    ],
    dependencies: [
        // For API calls to Twitter/X
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    ],
    targets: [
        .executableTarget(
            name: "TweetFlowPro",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "TweetFlowProTests",
            dependencies: ["TweetFlowPro"]
        ),
    ]
)
