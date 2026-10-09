// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnattiCore",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "AnattiCore", targets: ["AnattiCore"])
    ],
    targets: [
        .target(name: "AnattiCore"),
        .testTarget(name: "AnattiCoreTests", dependencies: ["AnattiCore"])
    ]
)
