import ChatTextInputPanelNode
import TelegramPresentationData
import UIKit
import XCTest

final class InputIconButtonComponentVoiceOverTests: XCTestCase {
    func testResolveSettingsUsesSettingsTitle() {
        let resolved = InputIconButtonComponentVoiceOver.resolveSettings(strings: defaultPresentationStrings, isEnabled: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Settings_Title)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveSettingsDisabledAddsNotEnabledTrait() {
        let resolved = InputIconButtonComponentVoiceOver.resolveSettings(strings: defaultPresentationStrings, isEnabled: false)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

