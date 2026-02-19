import MoreHeaderButton
import TelegramPresentationData
import UIKit
import XCTest

final class MoreHeaderButtonAccessibilityTests: XCTestCase {
    func testMoreHeaderButtonIsAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let button = MoreHeaderButton(color: .black, accessibilityLabel: defaultPresentationStrings.Common_More)
        button.onPressed = {
            didPress = true
        }
        
        XCTAssertTrue(button.isAccessibilityElement)
        XCTAssertEqual(button.accessibilityLabel, defaultPresentationStrings.Common_More)
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
        
        XCTAssertTrue(button.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
}
