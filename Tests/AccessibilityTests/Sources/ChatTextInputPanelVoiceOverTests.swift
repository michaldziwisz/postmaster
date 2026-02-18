import ChatTextInputPanelNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatTextInputPanelVoiceOverTests: XCTestCase {
    func testSendAsButtonResolvesLabelValueAndTraits() {
        let resolved = ChatTextInputPanelSendAsButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            currentPeerTitle: "My Channel",
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_SendMesageAs)
        XCTAssertEqual(resolved.value, "My Channel")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testSendAsButtonAddsNotEnabledTraitWhenDisabled() {
        let resolved = ChatTextInputPanelSendAsButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            currentPeerTitle: nil,
            isEnabled: false
        )
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testAttachmentButtonAddsNotEnabledTraitWhenDisabled() {
        let resolved = ChatTextInputPanelAttachmentButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: false
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_AttachMedia)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

