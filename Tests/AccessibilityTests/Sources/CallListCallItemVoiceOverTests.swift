import CallListUI
import TelegramPresentationData
import UIKit
import XCTest

final class CallListCallItemVoiceOverTests: XCTestCase {
    func testResolvesLabelValueAndTraits() {
        let resolved = CallListCallItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            status: defaultPresentationStrings.Call_VoiceOver_VoiceCallIncoming,
            date: "Yesterday",
            isEditing: false
        )
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.value, "\(defaultPresentationStrings.Call_VoiceOver_VoiceCallIncoming), Yesterday")
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testOmitsEmptyValueParts() {
        let resolved = CallListCallItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            status: nil,
            date: "",
            isEditing: false
        )
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertNil(resolved.value)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

