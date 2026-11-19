// swift-tools-version: 6.0
import PackageDescription

/// Domain and Data layers live in their own modules so the Clean Architecture
/// dependency rule is enforced by the compiler, not by convention:
///
///   App (Presentation + Coordinators)  ──▶  DataLayer  ──▶  Domain
///                     └─────────────────────────────────────▲
///
/// `Domain` has zero dependencies (not even CoreLocation or UIKit).
let package = Package(
    name: "OpenWeatherCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "DataLayer", dependencies: ["Domain"]),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer", "Domain"]),
    ],
    swiftLanguageModes: [.v6]
)
