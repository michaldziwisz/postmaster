import EntityKeyboard
import UIKit
import XCTest

final class GroupHeaderButtonsVoiceOverTests: XCTestCase {
    func testResolveSetsButtonLabelAndTraits() {
        let resolved = GroupHeaderButtonsVoiceOver.resolve(title: "Edit")
        
        XCTAssertEqual(resolved.label, "Edit")
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

