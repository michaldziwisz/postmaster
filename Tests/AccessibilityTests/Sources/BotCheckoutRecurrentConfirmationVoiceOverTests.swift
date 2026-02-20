import BotPaymentsUI
import TelegramPresentationData
import UIKit
import XCTest

final class BotCheckoutRecurrentConfirmationVoiceOverTests: XCTestCase {
    func testResolveToggleSelectedIsOnAndSelectedTrait() {
        let resolved = BotCheckoutRecurrentConfirmationVoiceOver.resolveToggle(
            strings: defaultPresentationStrings,
            label: "Terms",
            isSelected: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Terms")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_On)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveToggleDisabledAddsNotEnabledAndOmitsHint() {
        let resolved = BotCheckoutRecurrentConfirmationVoiceOver.resolveToggle(
            strings: defaultPresentationStrings,
            label: "Terms",
            isSelected: false,
            isEnabled: false
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveLinkEnabledAddsLinkTraitAndOpenLinkHint() {
        let resolved = BotCheckoutRecurrentConfirmationVoiceOver.resolveLink(
            strings: defaultPresentationStrings,
            label: "Terms",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertTrue(resolved.traits.contains(.link))
    }
}

