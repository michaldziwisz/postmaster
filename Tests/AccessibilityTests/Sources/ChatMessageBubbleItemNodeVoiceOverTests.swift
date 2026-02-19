import ChatMessageBubbleItemNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageBubbleItemNodeVoiceOverTests: XCTestCase {
    func testResolveAdCloseButton() {
        let resolved = ChatMessageBubbleItemNodeVoiceOver.resolveAdCloseButton(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveAuthorNameButtonUsesNameAndOpenHint() {
        let resolved = ChatMessageBubbleItemNodeVoiceOver.resolveAuthorNameButton(
            strings: defaultPresentationStrings,
            title: "Alice",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveAuthorNameButtonDisabledAddsNotEnabledAndClearsHint() {
        let resolved = ChatMessageBubbleItemNodeVoiceOver.resolveAuthorNameButton(
            strings: defaultPresentationStrings,
            title: "Alice",
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.hint, nil)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}
