import ChatButtonKeyboardInputNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatButtonKeyboardInputNodeVoiceOverTests: XCTestCase {
    func testResolveButtonTrimsTitleAndIsButton() {
        let resolved = ChatButtonKeyboardInputNodeVoiceOver.resolveButton(
            strings: defaultPresentationStrings,
            title: "  Hello  ",
            kind: .standard,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Hello")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.link))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
    
    func testResolveButtonOpenLinkAddsHintAndLinkTrait() {
        let resolved = ChatButtonKeyboardInputNodeVoiceOver.resolveButton(
            strings: defaultPresentationStrings,
            title: "Open",
            kind: .openLink,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveButtonDisabledAddsNotEnabledAndDisablesActivation() {
        let resolved = ChatButtonKeyboardInputNodeVoiceOver.resolveButton(
            strings: defaultPresentationStrings,
            title: "Test",
            kind: .standard,
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(ChatButtonKeyboardInputNodeVoiceOver.shouldActivate(isEnabled: false))
    }
}

