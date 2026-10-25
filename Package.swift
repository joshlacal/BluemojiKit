// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "BluemojiKit",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [.library(name: "BluemojiKit", targets: ["BluemojiKit"])],
  dependencies: [
    .package(url: "https://github.com/joshlacal/Petrel.git", revision: "819e6fc3363e4b0973b191a593af6b0f25b63bf3"),
    .package(url: "https://github.com/joshlacal/PetrelBluemoji.git", revision: "fea6c8dd9a2f4f4e3a9b0bc0ae777c59e5b95c6a"),
    .package(url: "https://github.com/joshlacal/AdaptiveGlyphKit.git", revision: "22c1667e5add37217da76b4668577eaa196724f2"),
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
