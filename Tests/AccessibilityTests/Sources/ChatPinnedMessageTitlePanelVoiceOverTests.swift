import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatPinnedMessageTitlePanelVoiceOverTests: XCTestCase {
    func testResolveMainUsesOpenHintAndButtonTrait() {
        let resolved = ChatPinnedMessageTitlePanelVoiceOver.resolveMain(
            strings: defaultPresentationStrings,
            title: "Pinned Message #2",
            message: "Hello",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Pinned Message #2")
        XCTAssertEqual(resolved.value, "Hello")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveMainTrimsAndOmitsEmptyValue() {
        let resolved = ChatPinnedMessageTitlePanelVoiceOver.resolveMain(
            strings: defaultPresentationStrings,
            title: "  Pinned Message  ",
            message: "   ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Pinned Message")
        XCTAssertNil(resolved.value)
    }
    
    func testResolveCloseButtonLabel() {
        let resolved = ChatPinnedMessageTitlePanelVoiceOver.resolveCloseButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveListButtonUsesPinnedMessagesTitle() {
        let resolved = ChatPinnedMessageTitlePanelVoiceOver.resolveListButton(strings: defaultPresentationStrings, totalCount: 3, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_TitlePinnedMessages(3))
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveDisabledAddsNotEnabledTrait() {
        let resolved = ChatPinnedMessageTitlePanelVoiceOver.resolveMain(
            strings: defaultPresentationStrings,
            title: "Pinned Message",
            message: "Hello",
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
}
