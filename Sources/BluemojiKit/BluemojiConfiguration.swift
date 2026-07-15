import Foundation

/// Configuration for a ``BluemojiRenderer`` — which AppView to verify against
/// and how large forged glyph images may be.
public struct BluemojiConfiguration: Sendable {
  /// AppView + blob-CDN host (default `https://moji.blue`).
  public var host: URL
  /// Longer-edge pixel cap passed to the glyph forge.
  public var maximumDimension: CGFloat

  public init(host: URL = URL(string: "https://moji.blue")!, maximumDimension: CGFloat = 512) {
    self.host = host
    self.maximumDimension = maximumDimension
  }

  public static let `default` = BluemojiConfiguration()
}
