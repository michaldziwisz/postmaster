import PremiumUI
import TelegramPresentationData
import UIKit
import XCTest

final class GiftOptionItemVoiceOverTests: XCTestCase {
    func testResolveEnabledAddsOpenHintAndButtonTrait() {
        let resolved = GiftOptionItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: true,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveDisabledOmitsHintAndAddsNotEnabledTrait() {
        let resolved = GiftOptionItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: false,
            isSelected: false
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveSelectedAddsSelectedTrait() {
        let resolved = GiftOptionItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: true,
            isSelected: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
}

