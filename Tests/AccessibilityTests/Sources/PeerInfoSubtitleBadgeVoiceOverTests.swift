import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoSubtitleBadgeVoiceOverTests: XCTestCase {
    func testHiddenStatusBadgeIsButtonWithOpenHint() {
        let title = defaultPresentationStrings.PeerInfo_HiddenStatusBadge
        let resolved = PeerInfoSubtitleBadgeVoiceOver.resolve(strings: defaultPresentationStrings, title: title)
        XCTAssertEqual(resolved.label, title)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

