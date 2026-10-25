// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "BluemojiKit",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [.library(name: "BluemojiKit", targets: ["BluemojiKit"])],
  dependencies: [
    .package(url: "https://github.com/joshlacal/Petrel.git", revision: "cc2999e1f4746a7c246d76dce09f4176ec0768a1"),
    .package(url: "https://github.com/joshlacal/PetrelBluemoji.git", revision: "78cab63570165f872b2c03004263cf206dc90657"),
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
