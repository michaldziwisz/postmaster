import CallListUI
import TelegramPresentationData
import UIKit
import XCTest

final class CallListCallItemInfoButtonVoiceOverTests: XCTestCase {
    func testResolvesInfoButtonWhenNotEditing() {
        let resolved = CallListCallItemInfoButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEditing: false
        )
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_Info)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testHidesInfoButtonWhenEditing() {
        let resolved = CallListCallItemInfoButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEditing: true
        )
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertNil(resolved.label)
    }
}

