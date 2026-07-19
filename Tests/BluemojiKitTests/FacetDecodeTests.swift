import Foundation
import Petrel
import PetrelBluemoji
import Testing
@testable import BluemojiKit

@Suite("Facet detection on Petrel-decoded facets")
struct FacetDecodeTests {

  /// The facet exactly as the AppView returns it (from
  /// at://did:plc:kmzpsik7s5y5fwu7nnkngfx4/app.bsky.feed.post/3mqchxbzgqh2k).
  /// Decoding through Petrel is the real production path: an unregistered
  /// `$type` decodes as `.unexpected(.unknownType(_, .object(...)))`, not
  /// `.unexpected(.object(...))`.
  private static let liveFacetJSON = Data("""
    {
      "features": [
        {
          "$type": "blue.moji.richtext.facet",
          "alt": "test emoji",
          "did": "did:plc:kmzpsik7s5y5fwu7nnkngfx4",
          "formats": {
            "$type": "blue.moji.richtext.facet#formats_v1",
            "png_128": "bafkreid2gz6qqan76e5ixrw2tgrwof5aqhulxj2gqptryn7j7s4og5vepm",
            "webp_128": "bafkreifei453knthohtbiwxllld676kpmanh6fny2wvdctkj5f745swpra"
          },
          "name": ":test1:"
        }
      ],
      "index": {
        "byteEnd": 17,
        "byteStart": 10
      }
    }
    """.utf8)

  @Test("extracts a claim from a facet decoded by Petrel")
  func extractsClaimFromDecodedFacet() throws {
    let facet = try JSONDecoder().decode(AppBskyRichtextFacet.self, from: Self.liveFacetJSON)
    let claims = BluemojiFacet.claims(in: [facet])
    #expect(claims == [BluemojiClaim(
      did: "did:plc:kmzpsik7s5y5fwu7nnkngfx4", name: ":test1:",
      byteStart: 10, byteEnd: 17)])
  }

  @Test("extracts a claim from a registered (.knownType) facet feature")
  func extractsClaimFromKnownType() {
    let typed = BlueMojiRichtextFacet(
      did: "did:plc:kmzpsik7s5y5fwu7nnkngfx4", name: ":test1:",
      alt: "test emoji", adultOnly: nil, labels: nil,
      formats: .blueMojiRichtextFacetFormatsV1(BlueMojiRichtextFacet.Formats_v1(
        png_128: nil, webp_128: nil, gif_128: nil, apng_128: nil, lottie: nil)))
    let facet = AppBskyRichtextFacet(
      index: AppBskyRichtextFacet.ByteSlice(byteStart: 10, byteEnd: 17),
      features: [.unexpected(.knownType(typed))])
    let claims = BluemojiFacet.claims(in: [facet])
    #expect(claims == [BluemojiClaim(
      did: "did:plc:kmzpsik7s5y5fwu7nnkngfx4", name: ":test1:",
      byteStart: 10, byteEnd: 17)])
  }
}
