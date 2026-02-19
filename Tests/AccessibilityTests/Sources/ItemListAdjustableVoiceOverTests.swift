import ItemListUI
import UIKit
import XCTest

final class ItemListAdjustableVoiceOverTests: XCTestCase {
    func testResolveEnabledUsesAdjustableTrait() {
        let resolved = ItemListAdjustableVoiceOver.resolve(value: "50%", isEnabled: true)
        XCTAssertEqual(resolved.value, "50%")
        XCTAssertTrue(resolved.traits.contains(.adjustable))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveDisabledUsesNotEnabledTrait() {
        let resolved = ItemListAdjustableVoiceOver.resolve(value: "High", isEnabled: false)
        XCTAssertEqual(resolved.value, "High")
        XCTAssertTrue(resolved.traits.contains(.adjustable))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

