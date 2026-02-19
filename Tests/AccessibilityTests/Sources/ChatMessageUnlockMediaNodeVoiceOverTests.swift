import ChatMessageUnlockMediaNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageUnlockMediaNodeVoiceOverTests: XCTestCase {
    func testResolveUnlockButtonLabelUsesUnlockString() {
        let resolved = ChatMessageUnlockMediaNodeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            amountString: "123",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_PaidMedia_UnlockMedia("⭐️ 123").string)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveUnlockButtonDisabledAddsNotEnabledTrait() {
        let resolved = ChatMessageUnlockMediaNodeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            amountString: "1",
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

