import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatNavigationBarMoreButtonVoiceOverTests: XCTestCase {
    func testResolveUsesMoreLabelAndButtonTrait() {
        let resolved = ChatNavigationBarMoreButtonVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_More)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveAddsNotEnabledTraitWhenDisabled() {
        let resolved = ChatNavigationBarMoreButtonVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: false)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

