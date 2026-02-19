import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatOverlayNavigationBarVoiceOverTests: XCTestCase {
    func testResolveTitleTrimsTitleAndAddsOpenHint() {
        let resolved = ChatOverlayNavigationBarVoiceOver.resolveTitle(
            strings: defaultPresentationStrings,
            title: "  My Chat  ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "My Chat")
        XCTAssertNil(resolved.value)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveCloseButtonUsesCommonCloseLabel() {
        let resolved = ChatOverlayNavigationBarVoiceOver.resolveCloseButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

