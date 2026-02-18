import CallListUI
import TelegramPresentationData
import UIKit
import XCTest

final class CallListGroupCallJoinButtonVoiceOverTests: XCTestCase {
    func testResolvesJoinButtonWhenVisible() {
        let resolved = CallListGroupCallJoinButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isActive: false,
            isEditing: false
        )
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceChat_PanelJoin)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testHidesJoinButtonWhenActive() {
        let resolved = CallListGroupCallJoinButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isActive: true,
            isEditing: false
        )
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertNil(resolved.label)
    }
    
    func testHidesJoinButtonWhenEditing() {
        let resolved = CallListGroupCallJoinButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isActive: false,
            isEditing: true
        )
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertNil(resolved.label)
    }
}

