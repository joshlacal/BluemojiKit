import Petrel
import PetrelBluemoji

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
  /// Petrel decodes it into `.unexpected(container)`. The container's shape
  /// depends on registration: `.unknownType(type, .object(...))` when the
  /// blue.moji lexicons are unregistered (the default), `.knownType` when
  /// `PetrelBluemojiLexicons.register()` has run, or a bare `.object` when
  /// constructed in memory.
  public static func claims(in facets: [AppBskyRichtextFacet]) -> [BluemojiClaim] {
    var claims: [BluemojiClaim] = []
    for facet in facets {
      for feature in facet.features {
        guard case let .unexpected(container) = feature,
              let (did, name) = didAndName(from: container)
        else { continue }
        claims.append(BluemojiClaim(
          did: did, name: name,
          byteStart: facet.index.byteStart, byteEnd: facet.index.byteEnd))
      }
    }
    return claims
  }

  private static func didAndName(from container: ATProtocolValueContainer) -> (String, String)? {
    switch container {
    case let .unknownType(typeValue, inner):
      guard typeValue == type, case let .object(fields) = inner else { return nil }
      return didAndName(fromRaw: fields, checkType: false)
    case let .knownType(value):
      guard let typed = value as? BlueMojiRichtextFacet else { return nil }
      return (typed.did, typed.name)
    case let .object(fields):
      return didAndName(fromRaw: fields, checkType: true)
    default:
      return nil
    }
  }

  private static func didAndName(
    fromRaw fields: [String: ATProtocolValueContainer], checkType: Bool
  ) -> (String, String)? {
    if checkType {
      guard case let .string(typeValue)? = fields["$type"], typeValue == type else { return nil }
    }
    guard case let .string(did)? = fields["did"],
          case let .string(name)? = fields["name"]
    else { return nil }
    return (did, name)
  }
}
