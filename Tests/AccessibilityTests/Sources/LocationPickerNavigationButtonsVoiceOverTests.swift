import LocationUI
import TelegramPresentationData
import UIKit
import XCTest

final class LocationPickerNavigationButtonsVoiceOverTests: XCTestCase {
    func testResolveCancelUsesCloseLabelWhenNotBack() {
        let resolved = LocationPickerNavigationButtonsVoiceOver.resolveCancelOrBack(strings: defaultPresentationStrings, isBack: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveCancelUsesBackLabelWhenBack() {
        let resolved = LocationPickerNavigationButtonsVoiceOver.resolveCancelOrBack(strings: defaultPresentationStrings, isBack: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Back)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveSearchUsesSearchLabel() {
        let resolved = LocationPickerNavigationButtonsVoiceOver.resolveSearch(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Search)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

