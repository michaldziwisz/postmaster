import PeerInfoAvatarListNode
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoAvatarListSetByYouVoiceOverTests: XCTestCase {
    func testLinkTitleIsButtonWithOpenHint() {
        let resolved = PeerInfoAvatarListSetByYouVoiceOver.resolve(strings: defaultPresentationStrings, title: defaultPresentationStrings.UserInfo_PublicPhoto, isLink: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.UserInfo_PublicPhoto)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.staticText))
    }

    func testNonLinkTitleIsStaticTextWithoutHint() {
        let resolved = PeerInfoAvatarListSetByYouVoiceOver.resolve(strings: defaultPresentationStrings, title: defaultPresentationStrings.UserInfo_CustomPhoto, isLink: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.UserInfo_CustomPhoto)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

