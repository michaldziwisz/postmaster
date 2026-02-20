import InviteLinksUI
import TelegramPresentationData
import UIKit
import XCTest

final class InviteLinkHeaderItemVoiceOverTests: XCTestCase {
    func testResolveIncludesTitleAndText() {
        let resolved = InviteLinkHeaderItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Title",
            text: "Text",
            containsLink: false
        )
        
        XCTAssertEqual(resolved.label, "Title. Text")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
    }
    
    func testResolveWithoutTitleUsesTextOnly() {
        let resolved = InviteLinkHeaderItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: nil,
            text: "Text",
            containsLink: false
        )
        
        XCTAssertEqual(resolved.label, "Text")
    }
    
    func testResolveContainsLinkAddsHintAndLinkTrait() {
        let resolved = InviteLinkHeaderItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: nil,
            text: "Text",
            containsLink: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
    }
}

