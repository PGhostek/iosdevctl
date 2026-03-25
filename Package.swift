// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iosdevctl",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.3.0"
        ),
        .package(
            url: "https://github.com/grpc/grpc-swift.git",
            .upToNextMajor(from: "1.21.0")
        ),
        .package(
            url: "https://github.com/apple/swift-protobuf.git",
            .upToNextMajor(from: "1.25.0")
        )
    ],
    targets: [
        .executableTarget(
            name: "iosdevctl",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Sources/iosdevctl"
        )
    ]
)
