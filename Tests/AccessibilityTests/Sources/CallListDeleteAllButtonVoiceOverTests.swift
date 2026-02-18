import CallListUI
import TelegramPresentationData
import UIKit
import XCTest

final class CallListDeleteAllButtonVoiceOverTests: XCTestCase {
    func testResolvesLabelAndTraits() {
        let resolved = CallListDeleteAllButtonVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.CallList_DeleteAll)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

