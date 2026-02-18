import ChatScheduleTimeController
import TelegramPresentationData
import UIKit
import XCTest

final class ChatScheduleTimeScreenNavigationButtonsVoiceOverTests: XCTestCase {
    func testResolveClose() {
        let resolved = ChatScheduleTimeScreenNavigationButtonsVoiceOver.resolveClose(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

