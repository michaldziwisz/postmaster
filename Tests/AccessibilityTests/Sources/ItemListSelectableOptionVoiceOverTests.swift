import ItemListUI
import UIKit
import XCTest

final class ItemListSelectableOptionVoiceOverTests: XCTestCase {
    func testResolveSelectedEnabledAddsSelectedTrait() {
        let resolved = ItemListSelectableOptionVoiceOver.resolve(value: "Details", isSelected: true, isEnabled: true)
        XCTAssertEqual(resolved.value, "Details")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveUnselectedDisabledAddsNotEnabledTrait() {
        let resolved = ItemListSelectableOptionVoiceOver.resolve(value: nil, isSelected: false, isEnabled: false)
        XCTAssertNil(resolved.value)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

