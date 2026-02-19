import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoRecommendedPeersUnlockTextVoiceOverTests: XCTestCase {
    func testResolveBotsUnlockTextStripsMarkdown() {
        let resolved = PeerInfoRecommendedPeersUnlockTextVoiceOver.resolve(strings: defaultPresentationStrings, isBots: true)
        XCTAssertEqual(resolved.label, "Subscribe to Telegram Premium\nto unlock up to 100 similar bots.")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
    }
    
    func testResolveChannelsUnlockTextStripsMarkdown() {
        let resolved = PeerInfoRecommendedPeersUnlockTextVoiceOver.resolve(strings: defaultPresentationStrings, isBots: false)
        XCTAssertEqual(resolved.label, "Subscribe to Telegram Premium\nto unlock up to 100 similar channels.")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
    }
}

