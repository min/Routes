// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "Routes",
    products: [
        .library(
            name: "Routes",
            targets: ["Routes"]),
    ],
    targets: [
        .target(name: "Routes", path: "Routes")
    ]
)
