import ChatMessageFactCheckBubbleContentNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageFactCheckBubbleContentNodeVoiceOverTests: XCTestCase {
    func testResolveBadgeUsesWhatIsThisLabelAndOpenHint() {
        let resolved = ChatMessageFactCheckBubbleContentNodeVoiceOver.resolveBadge(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_FactCheck_WhatIsThis)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveBadgeDisabledAddsNotEnabledAndClearsHint() {
        let resolved = ChatMessageFactCheckBubbleContentNodeVoiceOver.resolveBadge(
            strings: defaultPresentationStrings,
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.hint, nil)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

