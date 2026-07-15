import Petrel
import Testing
@testable import BluemojiKit

@Suite("Facet detection")
struct FacetDetectionTests {

  /// Build a facet whose feature is a raw `blue.moji.richtext.facet` object
  /// (as Petrel decodes an unknown feature: `.unexpected(.object(...))`).
  private func bluemojiFacet(
    type: String = "blue.moji.richtext.facet",
    did: String = "did:plc:x", name: String = ":blobcat:",
    start: Int = 3, end: Int = 12
  ) -> AppBskyRichtextFacet {
    let object = ATProtocolValueContainer.object([
      "$type": .string(type),
      "did": .string(did),
      "name": .string(name),
    ])
    return AppBskyRichtextFacet(
      index: AppBskyRichtextFacet.ByteSlice(byteStart: start, byteEnd: end),
      features: [.unexpected(object)])
  }

  @Test("extracts a claim from a blue.moji facet")
  func extractsClaim() {
    let claims = BluemojiFacet.claims(in: [bluemojiFacet()])
    #expect(claims == [BluemojiClaim(did: "did:plc:x", name: ":blobcat:", byteStart: 3, byteEnd: 12)])
  }

  @Test("ignores non-bluemoji unexpected facets") func ignoresOther() {
    let other = bluemojiFacet(type: "app.example.other")
    #expect(BluemojiFacet.claims(in: [other]).isEmpty)
  }

  @Test("ignores first-party tag facets") func ignoresTag() {
    let tag = AppBskyRichtextFacet(
      index: AppBskyRichtextFacet.ByteSlice(byteStart: 0, byteEnd: 4),
      features: [.appBskyRichtextFacetTag(AppBskyRichtextFacet.Tag(tag: "hi"))])
    #expect(BluemojiFacet.claims(in: [tag]).isEmpty)
  }
}
