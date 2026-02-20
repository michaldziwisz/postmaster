import AlertCheckComponent
import TelegramPresentationData
import UIKit
import XCTest

final class AlertCheckComponentVoiceOverTests: XCTestCase {
    func testResolveWithoutLink() {
        let resolved = AlertCheckComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "I agree",
            isSelected: false,
            linkActionAvailable: false
        )
        
        XCTAssertEqual(resolved.label, "I agree")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.containsLinkAction)
    }
    
    func testResolveWithLinkAddsCustomActionFlag() {
        let resolved = AlertCheckComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Learn more at [telegram.org](https://telegram.org)",
            isSelected: true,
            linkActionAvailable: true
        )
        
        XCTAssertEqual(resolved.label, "Learn more at telegram.org")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertTrue(resolved.containsLinkAction)
    }
}

