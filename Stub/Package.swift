// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Stub",
    products: [
        .executable(name: "Stub", targets: ["Stub"]),
    ],
    targets: [
        .target(name: "Stub", dependencies: [])
    ]
)
