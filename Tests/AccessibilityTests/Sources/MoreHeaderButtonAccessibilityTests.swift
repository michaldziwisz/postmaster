import MoreHeaderButton
import UIKit
import XCTest

final class MoreHeaderButtonAccessibilityTests: XCTestCase {
    func testMoreHeaderButtonIsAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let button = MoreHeaderButton(color: .black)
        button.onPressed = {
            didPress = true
        }
        
        XCTAssertTrue(button.isAccessibilityElement)
        XCTAssertEqual(button.accessibilityLabel, "More")
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
        
        XCTAssertTrue(button.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
}

