import NavigationSearchComponent
import UIKit
import XCTest

final class NavigationSearchComponentVoiceOverTests: XCTestCase {
    func testSearchFieldResolvesLabelAndTraits() {
        let resolved = NavigationSearchComponentVoiceOver.resolveSearchField(placeholder: "Search")
        XCTAssertEqual(resolved.label, "Search")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.searchField))
    }
    
    func testClearButtonResolvesLabelAndTraits() {
        let resolved = NavigationSearchComponentVoiceOver.resolveClearButton(clear: "Clear")
        XCTAssertEqual(resolved.label, "Clear")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

