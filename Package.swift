// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Anatti",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "AnattiCore", targets: ["AnattiCore"]),
        .library(name: "AnattiPro", targets: ["AnattiPro"])
    ],
    targets: [
        .target(name: "AnattiCore"),
        .target(name: "AnattiPro", dependencies: ["AnattiCore"]),
        .testTarget(name: "AnattiCoreTests", dependencies: ["AnattiCore"]),
        .testTarget(name: "AnattiProTests", dependencies: ["AnattiPro"])
    ]
)
