import ContactListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ContactListActionItemVoiceOverTests: XCTestCase {
    func testResolvesButtonWithValueAndOpenHint() {
        let resolved = ContactListActionItemVoiceOver.resolve(strings: defaultPresentationStrings, title: "New Group", subtitle: "Create a group chat")
        XCTAssertEqual(resolved.label, "New Group")
        XCTAssertEqual(resolved.value, "Create a group chat")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testNilSubtitleHasNilValue() {
        let resolved = ContactListActionItemVoiceOver.resolve(strings: defaultPresentationStrings, title: "New Group", subtitle: nil)
        XCTAssertNil(resolved.value)
    }
}

