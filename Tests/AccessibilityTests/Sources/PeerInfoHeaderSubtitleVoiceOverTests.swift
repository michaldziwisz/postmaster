import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoHeaderSubtitleVoiceOverTests: XCTestCase {
    func testButtonSubtitleIsButtonWithOpenHint() {
        let resolved = PeerInfoHeaderSubtitleVoiceOver.resolve(strings: defaultPresentationStrings, subtitle: "General", isButton: true)
        XCTAssertEqual(resolved.label, "General")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.staticText))
    }

    func testStaticSubtitleIsStaticTextWithoutHint() {
        let resolved = PeerInfoHeaderSubtitleVoiceOver.resolve(strings: defaultPresentationStrings, subtitle: "online", isButton: false)
        XCTAssertEqual(resolved.label, "online")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

