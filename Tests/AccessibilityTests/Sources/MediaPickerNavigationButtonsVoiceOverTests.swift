import MediaPickerUI
import TelegramPresentationData
import UIKit
import XCTest

final class MediaPickerNavigationButtonsVoiceOverTests: XCTestCase {
    func testResolveCancelUsesCloseLabelWhenNotBack() {
        let resolved = MediaPickerNavigationButtonsVoiceOver.resolveCancelOrBack(strings: defaultPresentationStrings, isBack: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveCancelUsesBackLabelWhenBack() {
        let resolved = MediaPickerNavigationButtonsVoiceOver.resolveCancelOrBack(strings: defaultPresentationStrings, isBack: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Back)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveMoreUsesMoreLabel() {
        let resolved = MediaPickerNavigationButtonsVoiceOver.resolveMore(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_More)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

