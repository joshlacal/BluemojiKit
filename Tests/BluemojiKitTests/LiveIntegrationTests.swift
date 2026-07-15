import Foundation
import Petrel
import Testing
@testable import BluemojiKit

/// Opt-in live test against the real moji.blue AppView + CDN.
/// Run with: `BLUEMOJI_LIVE=1 xcrun --toolchain XcodeDefault swift test --filter LiveIntegrationTests`
@Suite("Live integration", .enabled(if: ProcessInfo.processInfo.environment["BLUEMOJI_LIVE"] != nil))
struct LiveIntegrationTests {
  @Test("verifies + forges the seeded :test1: emoji from the live AppView")
  func liveForge() async throws {
    let renderer = BluemojiRenderer()
    let item = try #require(
      await renderer.verify(did: "did:plc:w5pfavrjij2ax3ur34tvbkg2", name: ":test1:"),
      "expected the live AppView to return the :test1: record")
    #expect(item.inlineCID != nil)
    let glyph = try #require(await renderer.glyph(for: item),
      "expected a forged glyph from the live blob")
    #expect(glyph.contentIdentifier.contains(item.did))
  }
}
