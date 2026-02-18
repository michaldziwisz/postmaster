import ContactListUI
import UIKit
import XCTest

final class ContactsAddItemVoiceOverTests: XCTestCase {
    func testResolveSetsButtonTrait() {
        let resolved = ContactsAddItemVoiceOver.resolve(label: "Add +123")
        XCTAssertEqual(resolved.label, "Add +123")
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

