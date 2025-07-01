// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TrackEd",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TrackEd",
            targets: ["TrackEd"]),
    ],
    dependencies: [
        .package(url: "https://github.com/google/leveldb.git", from: "1.23.0")
    ],
    targets: [
        .target(
            name: "TrackEd",
            dependencies: [
                .product(name: "leveldb", package: "leveldb")
            ]),
        .testTarget(
            name: "TrackEdTests",
            dependencies: ["TrackEd"]),
    ]
)
