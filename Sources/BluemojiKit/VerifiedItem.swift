import Foundation

/// A `blue.moji.collection.item` as returned by the AppView's verified
/// `getItem` read — the trust anchor for rendering. Never construct this from a
/// self-attested facet; only from ``BluemojiRenderer`` verification.
public struct VerifiedItem: Sendable, Equatable {
  public let did: String
  public let name: String
  public let alt: String?
  public let adultOnly: Bool
  public let png128CID: String?
  public let webp128CID: String?

  /// Preferred inline blob CID (PNG first — simplest to decode).
  public var inlineCID: String? { png128CID ?? webp128CID }
}
