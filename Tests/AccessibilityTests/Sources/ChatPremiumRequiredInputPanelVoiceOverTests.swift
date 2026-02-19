import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatPremiumRequiredInputPanelVoiceOverTests: XCTestCase {
    func testResolveSetsValueOpenHintAndButtonTrait() {
        let title = defaultPresentationStrings.Chat_MessagingRestrictedPlaceholder("Alice").string
        let subtitle = defaultPresentationStrings.Chat_MessagingRestrictedPlaceholderAction
        
        let resolved = ChatPremiumRequiredInputPanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: title,
            subtitle: subtitle,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, title.trimmingCharacters(in: .whitespacesAndNewlines))
        XCTAssertEqual(resolved.value, subtitle)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveAddsNotEnabledTraitWhenDisabled() {
        let resolved = ChatPremiumRequiredInputPanelVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Premium required",
            subtitle: nil,
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
}

