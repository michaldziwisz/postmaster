import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoHeaderTextFieldClearButtonVoiceOverTests: XCTestCase {
    func testResolveHiddenClearButtonIsNotAccessibilityElement() {
        let resolved = PeerInfoHeaderTextFieldClearButtonVoiceOver.resolve(strings: defaultPresentationStrings, isHidden: true)
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Editing_ClearText)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveVisibleClearButtonIsAccessibilityElementWithButtonTrait() {
        let resolved = PeerInfoHeaderTextFieldClearButtonVoiceOver.resolve(strings: defaultPresentationStrings, isHidden: false)
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Editing_ClearText)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

