import ChatTextInputPanelNode
import TelegramPresentationData
import UIKit
import XCTest

final class StarReactionButtonComponentVoiceOverTests: XCTestCase {
    func testResolveStarsButtonUsesTitleAndValue() {
        let resolved = StarReactionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            count: 10,
            isFilled: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.SendStarReactions_Title)
        XCTAssertEqual(resolved.value, "10")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveStarsButtonFilledAddsSelectedTrait() {
        let resolved = StarReactionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            count: 1,
            isFilled: true,
            isEnabled: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveStarsButtonZeroCountHasNoValue() {
        let resolved = StarReactionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            count: 0,
            isFilled: false,
            isEnabled: true
        )
        
        XCTAssertNil(resolved.value)
    }
}

