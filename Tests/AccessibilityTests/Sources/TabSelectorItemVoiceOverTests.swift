import TabSelectorComponent
import UIKit
import XCTest

final class TabSelectorItemVoiceOverTests: XCTestCase {
    func testSelectedEnabledResolvesSelectedTrait() {
        let resolved = TabSelectorItemVoiceOver.resolve(title: "All", isSelected: true, isEnabled: true)
        XCTAssertEqual(resolved.label, "All")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testDisabledResolvesNotEnabledTrait() {
        let resolved = TabSelectorItemVoiceOver.resolve(title: "All", isSelected: false, isEnabled: false)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}
