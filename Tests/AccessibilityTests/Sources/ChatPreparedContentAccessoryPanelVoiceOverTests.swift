import TelegramPresentationData
import AccessoryPanelNode
import UIKit
import XCTest

final class ChatPreparedContentAccessoryPanelVoiceOverTests: XCTestCase {
    func testResolveProvidesOpenHintAndCloseActionWhenEnabled() {
        let resolved = ChatPreparedContentAccessoryPanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            label: "Edit message",
            value: "Hello",
            isEnabled: true,
            includesGoToOriginalMessage: false
        )
        
        XCTAssertEqual(resolved.label, "Edit message")
        XCTAssertEqual(resolved.value, "Hello")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        
        XCTAssertEqual(resolved.customActions.count, 1)
        XCTAssertEqual(resolved.customActions[0].kind, .close)
        XCTAssertEqual(resolved.customActions[0].name, defaultPresentationStrings.VoiceOver_DiscardPreparedContent)
    }
    
    func testResolveAddsNotEnabledTraitAndOmitsHintWhenDisabled() {
        let resolved = ChatPreparedContentAccessoryPanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            label: "Edit message",
            value: "Hello",
            isEnabled: false,
            includesGoToOriginalMessage: false
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveAddsGoToOriginalMessageActionWhenRequested() {
        let resolved = ChatPreparedContentAccessoryPanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            label: "Reply",
            value: nil,
            isEnabled: true,
            includesGoToOriginalMessage: true
        )
        
        XCTAssertEqual(resolved.customActions.count, 2)
        XCTAssertEqual(resolved.customActions[1].kind, .goToOriginalMessage)
        XCTAssertEqual(resolved.customActions[1].name, defaultPresentationStrings.VoiceOver_Chat_GoToOriginalMessage)
    }
}
