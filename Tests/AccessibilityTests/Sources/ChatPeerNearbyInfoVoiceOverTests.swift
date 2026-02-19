import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatPeerNearbyInfoVoiceOverTests: XCTestCase {
    func testResolveTrimsLabelAndAddsOpenHint() {
        let resolved = ChatPeerNearbyInfoVoiceOver.resolve(
            strings: defaultPresentationStrings,
            label: "  Nearby users  ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Nearby users")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

