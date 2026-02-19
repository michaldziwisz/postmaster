import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatMessageActionUrlAuthVoiceOverTests: XCTestCase {
    func testResolveAuthorizeToggleOnAddsSelectedAndOnValue() {
        let resolved = ChatMessageActionUrlAuthVoiceOver.resolveAuthorizeToggle(
            strings: defaultPresentationStrings,
            labelText: " Log in ",
            isOn: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Log in")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_On)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveAllowWriteToggleDisabledAddsNotEnabledTraitAndClearsHint() {
        let resolved = ChatMessageActionUrlAuthVoiceOver.resolveAllowWriteToggle(
            strings: defaultPresentationStrings,
            labelText: "Allow messages",
            isOn: false,
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_Off)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

