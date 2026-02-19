import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatInviteRequestsTitlePanelVoiceOverTests: XCTestCase {
    func testResolveMainSetsOpenHintAndButtonTrait() {
        let resolved = ChatInviteRequestsTitlePanelVoiceOver.resolveMain(
            strings: defaultPresentationStrings,
            count: 3,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_RequestsToJoin(3))
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveCloseButtonUsesCommonCloseLabel() {
        let resolved = ChatInviteRequestsTitlePanelVoiceOver.resolveCloseButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

