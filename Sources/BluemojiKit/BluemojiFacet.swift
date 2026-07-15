import Petrel

/// A self-attested `blue.moji.richtext.facet` claim extracted from a post's
/// rich-text facets. **Not** yet verified — resolve it against the AppView
/// (``BluemojiRenderer``) before rendering anything.
public struct BluemojiClaim: Sendable, Equatable {
  public let did: String
  public let name: String
  public let byteStart: Int
  public let byteEnd: Int
}

public enum BluemojiFacet {
  public static let type = "blue.moji.richtext.facet"

  /// Extract Bluemoji claims from a post's facets.
  ///
  /// A `blue.moji.richtext.facet` feature is not a first-party Bluesky type, so
  /// Petrel decodes it into `.unexpected(container)`. We match its `$type` and
  /// read `did` / `name` straight out of the raw container.
  public static func claims(in facets: [AppBskyRichtextFacet]) -> [BluemojiClaim] {
    var claims: [BluemojiClaim] = []
    for facet in facets {
      for feature in facet.features {
        guard case let .unexpected(container) = feature,
              case let .object(fields) = container,
              case let .string(typeValue)? = fields["$type"], typeValue == type,
              case let .string(did)? = fields["did"],
              case let .string(name)? = fields["name"]
        else { continue }
        claims.append(BluemojiClaim(
          did: did, name: name,
          byteStart: facet.index.byteStart, byteEnd: facet.index.byteEnd))
      }
    }
    return claims
  }
}
