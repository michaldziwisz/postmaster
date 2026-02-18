import CountrySelectionUI
import TelegramPresentationData
import UIKit
import XCTest

final class AuthorizationSequenceCountrySelectionNavigationButtonsVoiceOverTests: XCTestCase {
    func testResolveCloseUsesCloseLabel() {
        let resolved = AuthorizationSequenceCountrySelectionNavigationButtonsVoiceOver.resolveClose(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveSearchUsesSearchLabel() {
        let resolved = AuthorizationSequenceCountrySelectionNavigationButtonsVoiceOver.resolveSearch(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Search)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testShouldShowSearchButton() {
        XCTAssertTrue(AuthorizationSequenceCountrySelectionNavigationButtonsVoiceOver.shouldShowSearchButton(isSearching: false))
        XCTAssertFalse(AuthorizationSequenceCountrySelectionNavigationButtonsVoiceOver.shouldShowSearchButton(isSearching: true))
    }
}

