// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NativePlaylistPlayer",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "NativePlaylistPlayer",
            targets: ["NativePlaylistPlayerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "NativePlaylistPlayerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/NativePlaylistPlayerPlugin"),
        .testTarget(
            name: "NativePlaylistPlayerPluginTests",
            dependencies: ["NativePlaylistPlayerPlugin"],
            path: "ios/Tests/NativePlaylistPlayerPluginTests")
    ]
)