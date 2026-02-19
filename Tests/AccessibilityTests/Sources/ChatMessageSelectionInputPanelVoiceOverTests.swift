import ChatMessageSelectionInputPanelNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageSelectionInputPanelVoiceOverTests: XCTestCase {
    func testResolveDeleteButtonAddsNotEnabledTraitWhenDisabled() {
        let resolved = ChatMessageSelectionInputPanelVoiceOver.resolveDeleteButton(
            strings: defaultPresentationStrings,
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_MessageContextDelete)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveForwardButtonDoesNotAddNotEnabledWhenEnabled() {
        let resolved = ChatMessageSelectionInputPanelVoiceOver.resolveForwardButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_MessageContextForward)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
}

