import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListToggleVoiceOverTests: XCTestCase {
    func testResolveOnEnabledUsesSelectedTraitAndSwitchHint() {
        let resolved = ItemListToggleVoiceOver.resolve(strings: defaultPresentationStrings, isOn: true, isEnabled: true)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_On)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveOffDisabledUsesNotEnabledTraitAndNoHint() {
        let resolved = ItemListToggleVoiceOver.resolve(strings: defaultPresentationStrings, isOn: false, isEnabled: false)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_Off)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
}

