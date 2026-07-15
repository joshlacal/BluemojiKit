import CoreGraphics
import Foundation
import ImageIO
import Petrel
import Testing
import UniformTypeIdentifiers
@testable import BluemojiKit

// MARK: - URLProtocol stub

final class StubURLProtocol: URLProtocol {
  nonisolated(unsafe) static var handler: (@Sendable (URL) -> (Int, Data))?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    guard let url = request.url, let (status, data) = Self.handler?(url) else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL)); return
    }
    let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: data)
    client?.urlProtocolDidFinishLoading(self)
  }
  override func stopLoading() {}
}

@Suite("Enrich", .serialized)
struct EnrichTests {
  static let did = "did:plc:w5pfavrjij2ax3ur34tvbkg2"
  static let cid = "bafkreid2gz6qqan76e5ixrw2tgrwof5aqhulxj2gqptryn7j7s4og5vepm"

  static func getItemJSON(adult: Bool) -> Data {
    """
    {"uri":"at://\(did)/blue.moji.collection.item/test1","item":{"$type":"blue.moji.collection.item#itemView","uri":"at://\(did)/blue.moji.collection.item/test1","cid":"bafyreigcbejsa3332dexqnqg5t5nx5d46g57u2nndfotuiwjsq3hvsmkfa","did":"\(did)","name":":test1:","alt":"test1","createdAt":"2026-07-08T19:13:10.369Z","formats":{"$type":"blue.moji.collection.item#formats_v1","png_128":{"ref":{"$link":"\(cid)"},"size":21278,"$type":"blob","mimeType":"image/png"}},"adultOnly":\(adult)}}
    """.data(using: .utf8)!
  }

  static func samplePNG() -> Data {
    let ctx = CGContext(data: nil, width: 128, height: 128, bitsPerComponent: 8, bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(CGColor(red: 0.1, green: 0.4, blue: 0.95, alpha: 1))
    ctx.fillEllipse(in: CGRect(x: 8, y: 8, width: 112, height: 112))
    let out = NSMutableData()
    let dest = CGImageDestinationCreateWithData(out, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
    CGImageDestinationFinalize(dest)
    return out as Data
  }

  static func session() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    return URLSession(configuration: config)
  }

  /// Facet claim over ":test1:" in "hi :test1:" (bytes 3..10).
  static func facet() -> AppBskyRichtextFacet {
    AppBskyRichtextFacet(
      index: AppBskyRichtextFacet.ByteSlice(byteStart: 3, byteEnd: 10),
      features: [.unexpected(.object([
        "$type": .string("blue.moji.richtext.facet"),
        "did": .string(did), "name": .string(":test1:"),
      ]))])
  }

  @Test("splices a glyph over the alias on success")
  func splices() async {
    StubURLProtocol.handler = { url in
      if url.path.contains("getItem") { return (200, Self.getItemJSON(adult: false)) }
      if url.path.contains("/img/") { return (200, Self.samplePNG()) }
      return (404, Data())
    }
    let renderer = BluemojiRenderer(session: Self.session())
    let out = await renderer.enrich(
      AttributedString("hi :test1:"), text: "hi :test1:", facets: [Self.facet()], allowAdult: false)
    #expect(String(out.characters) == "hi \u{FFFC}")
  }

  @Test("adultOnly without allowAdult keeps the alias text")
  func adultGated() async {
    StubURLProtocol.handler = { url in
      if url.path.contains("getItem") { return (200, Self.getItemJSON(adult: true)) }
      if url.path.contains("/img/") { return (200, Self.samplePNG()) }
      return (404, Data())
    }
    let renderer = BluemojiRenderer(session: Self.session())
    let out = await renderer.enrich(
      AttributedString("hi :test1:"), text: "hi :test1:", facets: [Self.facet()], allowAdult: false)
    #expect(String(out.characters) == "hi :test1:")
  }

  @Test("a 404 keeps the alias text")
  func notFound() async {
    StubURLProtocol.handler = { _ in (404, Data()) }
    let renderer = BluemojiRenderer(session: Self.session())
    let out = await renderer.enrich(
      AttributedString("hi :test1:"), text: "hi :test1:", facets: [Self.facet()], allowAdult: false)
    #expect(String(out.characters) == "hi :test1:")
  }
}
