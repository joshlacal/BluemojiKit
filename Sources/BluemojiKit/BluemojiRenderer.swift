import AdaptiveGlyphKit
import Foundation
import Petrel
import PetrelBluemoji

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Renders verified Bluemoji glyphs into post text.
///
/// Detects `blue.moji.richtext.facet` claims, verifies each against the AppView
/// (`blue.moji.collection.getItem`), fetches the verified blob, forges an
/// adaptive image glyph, and splices it into the post's `AttributedString`.
/// Every failure falls back to the `:alias:` text; nothing renders from a
/// self-attested facet.
public actor BluemojiRenderer {
  private let configuration: BluemojiConfiguration
  private let session: URLSession
  private var itemCache: [String: VerifiedItem?] = [:]     // "did\u{0}name" -> item (nil = negative)
  private var glyphCache: [String: NSAdaptiveImageGlyph] = [:]  // "did/cid"

  public init(configuration: BluemojiConfiguration = .default, session: URLSession = .shared) {
    self.configuration = configuration
    self.session = session
  }

  // MARK: Public

  /// Replace `blue.moji` facet ranges in `base` with verified glyph runs.
  /// Returns `base` unchanged if nothing resolves.
  public func enrich(
    _ base: AttributedString,
    text: String,
    facets: [AppBskyRichtextFacet],
    allowAdult: Bool
  ) async -> AttributedString {
    let claims = BluemojiFacet.claims(in: facets)
    guard !claims.isEmpty else { return base }

    struct Replacement { let charStart: Int; let charEnd: Int; let run: AttributedString }
    var replacements: [Replacement] = []

    for claim in claims {
      guard let item = await verify(did: claim.did, name: claim.name) else { continue }
      if item.adultOnly && !allowAdult { continue }            // gate → keep :alias:
      guard let glyph = await glyph(for: item),
            let run = AttributedString(adaptiveImageGlyph: glyph),
            let cStart = Self.characterOffset(claim.byteStart, in: text),
            let cEnd = Self.characterOffset(claim.byteEnd, in: text),
            cStart < cEnd
      else { continue }
      replacements.append(Replacement(charStart: cStart, charEnd: cEnd, run: run))
    }
    guard !replacements.isEmpty else { return base }

    // Apply highest-offset-first so earlier character offsets stay valid.
    var enriched = base
    for r in replacements.sorted(by: { $0.charStart > $1.charStart }) {
      let count = enriched.characters.count
      guard r.charStart >= 0, r.charStart < r.charEnd, r.charEnd <= count else { continue }
      let s = enriched.index(enriched.startIndex, offsetByCharacters: r.charStart)
      let e = enriched.index(enriched.startIndex, offsetByCharacters: r.charEnd)
      enriched.replaceSubrange(s..<e, with: r.run)
    }
    return enriched
  }

  // MARK: Verification

  func verify(did: String, name: String) async -> VerifiedItem? {
    let key = "\(did)\u{0}\(name)"
    if let cached = itemCache[key] { return cached }

    var components = URLComponents(url: configuration.host, resolvingAgainstBaseURL: false)
    components?.path = "/xrpc/blue.moji.collection.getItem"
    components?.queryItems = [
      URLQueryItem(name: "repo", value: did),
      URLQueryItem(name: "name", value: name),
    ]
    guard let url = components?.url else { itemCache[key] = .some(nil); return nil }

    let item: VerifiedItem?
    do {
      let (data, response) = try await session.data(from: url)
      guard (response as? HTTPURLResponse)?.statusCode == 200 else { item = nil; itemCache[key] = .some(nil); return nil }
      item = Self.decodeItem(data)
    } catch {
      item = nil
    }
    itemCache[key] = .some(item)
    return item
  }

  /// Decode a `getItem` response body into a ``VerifiedItem``.
  static func decodeItem(_ data: Data) -> VerifiedItem? {
    guard let output = try? JSONDecoder().decode(BlueMojiCollectionGetItem.Output.self, from: data)
    else { return nil }
    let view = output.item
    var png: String?, webp: String?
    switch view.formats {
    case let .blueMojiCollectionItemFormatsV1(f):
      png = f.png_128?.ref?.cid.string; webp = f.webp_128?.ref?.cid.string
    case let .blueMojiCollectionItemFormatsV0(f):
      png = f.png_128?.ref?.cid.string; webp = f.webp_128?.ref?.cid.string
    case .unexpected:
      break
    }
    return VerifiedItem(
      did: view.did?.didString() ?? "",
      name: view.name,
      alt: view.alt,
      adultOnly: view.adultOnly ?? false,
      png128CID: png, webp128CID: webp)
  }

  // MARK: Glyph

  func glyph(for item: VerifiedItem) async -> NSAdaptiveImageGlyph? {
    guard let cid = item.inlineCID else { return nil }
    let key = "\(item.did)/\(cid)"
    if let cached = glyphCache[key] { return cached }

    let url = configuration.host
      .appendingPathComponent("img")
      .appendingPathComponent(item.did)
      .appendingPathComponent(cid)
    guard let data = try? await session.data(from: url).0 else { return nil }

    guard let glyph = AdaptiveImageGlyphForge.makeGlyph(
      imageData: data,
      contentIdentifier: key,
      accessibilityDescription: item.alt ?? item.name,
      maximumDimension: configuration.maximumDimension)
    else { return nil }
    glyphCache[key] = glyph
    return glyph
  }

  // MARK: Helpers

  /// UTF-8 byte offset in `text` → character offset (for `AttributedString` indexing).
  static func characterOffset(_ byteOffset: Int, in text: String) -> Int? {
    guard let u = text.utf8.index(text.utf8.startIndex, offsetBy: byteOffset, limitedBy: text.utf8.endIndex),
          let c = u.samePosition(in: text) else { return nil }
    return text.distance(from: text.startIndex, to: c)
  }
}
