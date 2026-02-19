import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatVerifiedPeerTitlePanelVoiceOverTests: XCTestCase {
    func testResolveTrimsDescription() {
        let resolved = ChatVerifiedPeerTitlePanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            description: "  Verified by Example  ",
            hasLink: false
        )
        
        XCTAssertEqual(resolved.label, "Verified by Example")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
    
    func testResolveWithLinkAddsButtonTraitAndLinkHint() {
        let resolved = ChatVerifiedPeerTitlePanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            description: "Verified by Example https://example.com",
            hasLink: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

