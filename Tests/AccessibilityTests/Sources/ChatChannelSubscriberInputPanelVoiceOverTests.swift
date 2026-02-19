import ChatChannelSubscriberInputPanelNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatChannelSubscriberInputPanelVoiceOverTests: XCTestCase {
    func testResolveGiftButtonUsesGiftPremiumLabel() {
        let resolved = ChatChannelSubscriberInputPanelVoiceOver.resolveGiftButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_GiftPremium)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveSearchButtonUsesCommonSearchLabel() {
        let resolved = ChatChannelSubscriberInputPanelVoiceOver.resolveSearchButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Search)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

