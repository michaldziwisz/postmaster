import ChatMessageActionButtonsNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageActionButtonsNodeVoiceOverTests: XCTestCase {
    func testResolveButtonTrimsTitleAndIsButton() {
        let resolved = ChatMessageActionButtonsNodeVoiceOver.resolveButton(
            strings: defaultPresentationStrings,
            title: "  Hello  ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Hello")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertTrue(ChatMessageActionButtonsNodeVoiceOver.shouldActivate(isEnabled: true))
    }
    
    func testResolveButtonDisabledAddsNotEnabledAndDisablesActivation() {
        let resolved = ChatMessageActionButtonsNodeVoiceOver.resolveButton(
            strings: defaultPresentationStrings,
            title: "Test",
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(ChatMessageActionButtonsNodeVoiceOver.shouldActivate(isEnabled: false))
    }
    
    func testResolveButtonEmptyTitleFallsBackToOK() {
        let resolved = ChatMessageActionButtonsNodeVoiceOver.resolveButton(
            strings: defaultPresentationStrings,
            title: "   ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_OK)
    }
}

