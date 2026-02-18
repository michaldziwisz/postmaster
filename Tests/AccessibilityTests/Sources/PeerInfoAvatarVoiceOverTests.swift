import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoAvatarVoiceOverTests: XCTestCase {
    func testEnabledAvatarIsButtonWithPhotoLabelAndOpenHint() {
        let resolved = PeerInfoAvatarVoiceOver.resolve(strings: defaultPresentationStrings, peerTitle: "Alice", isEnabled: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Photo)
        XCTAssertEqual(resolved.value, "Alice")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }

    func testDisabledAvatarIsNotEnabledButtonWithoutHint() {
        let resolved = PeerInfoAvatarVoiceOver.resolve(strings: defaultPresentationStrings, peerTitle: "Alice", isEnabled: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Photo)
        XCTAssertEqual(resolved.value, "Alice")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

