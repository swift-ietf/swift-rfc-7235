// swift-tools-version: 6.3.3

import Foundation
import PackageDescription

extension String {
    static let rfc7235: Self = "RFC_7235"
}

extension Target.Dependency {
    static var rfc7235: Self { .target(name: .rfc7235) }
}

let package = Package(
    name: "swift-rfc-7235",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: .rfc7235, targets: [.rfc7235]),
    ],
    dependencies: [
        // Add RFC dependencies here as needed
        // .package(url: "https://github.com/swift-ietf/swift-rfc-1123.git", branch: "main"),
    ],
    targets: [
        .target(
            name: .rfc7235,
            dependencies: [
                // Add target dependencies here
            ]
        ),
        .testTarget(
            name: .rfc7235.tests,
            dependencies: [
                .rfc7235
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }