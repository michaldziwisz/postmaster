import ChatPresentationInterfaceState
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
    
    func testBoostToUnrestrictButtonResolvesLabelValueAndTraitsForTimestamp() {
        let resolved = ChatTextInputPanelBoostToUnrestrictButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            slowmodeState: ChatSlowmodeState(timeout: 0, variant: .timestamp(112)),
            nowTimestamp: 100,
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_BoostToUnrestrictText)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Chat_SlowmodeTooltip("0:12").string)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.updatesFrequently))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testBoostToUnrestrictButtonResolvesPendingMessagesValue() {
        let resolved = ChatTextInputPanelBoostToUnrestrictButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            slowmodeState: ChatSlowmodeState(timeout: 0, variant: .pendingMessages),
            nowTimestamp: 0,
            isEnabled: true
        )
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Chat_SlowmodeTooltipPending)
    }
}
