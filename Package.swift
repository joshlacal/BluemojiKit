// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "BluemojiKit",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [.library(name: "BluemojiKit", targets: ["BluemojiKit"])],
  dependencies: [
    .package(url: "https://github.com/joshlacal/Petrel.git", from: "1.0.1"),
    .package(url: "https://github.com/joshlacal/PetrelBluemoji.git", from: "0.1.0"),
    .package(url: "https://github.com/joshlacal/AdaptiveGlyphKit.git", from: "0.1.0"),
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
