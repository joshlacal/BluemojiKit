// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "BluemojiKit",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [.library(name: "BluemojiKit", targets: ["BluemojiKit"])],
  dependencies: [
    .package(path: "../Petrel"),
    .package(path: "../PetrelBluemoji"),
    .package(path: "../AdaptiveGlyphKit"),
  ],
  targets: [
    .target(name: "BluemojiKit", dependencies: [
      .product(name: "Petrel", package: "Petrel"),
      .product(name: "PetrelBluemoji", package: "PetrelBluemoji"),
      .product(name: "AdaptiveGlyphKit", package: "AdaptiveGlyphKit"),
    ]),
    .testTarget(name: "BluemojiKitTests", dependencies: ["BluemojiKit"]),
  ]
)
