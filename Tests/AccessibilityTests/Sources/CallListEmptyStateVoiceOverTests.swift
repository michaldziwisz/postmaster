import CallListUI
import TelegramPresentationData
import UIKit
import XCTest

final class CallListEmptyStateVoiceOverTests: XCTestCase {
    func testResolvesAllCallsEmptyStateTextAndButton() {
        let resolved = CallListEmptyStateVoiceOver.resolve(strings: defaultPresentationStrings, isMissed: false)
        XCTAssertEqual(resolved.text, defaultPresentationStrings.Calls_NoVoiceAndVideoCallsPlaceholder)
        XCTAssertEqual(resolved.button.label, defaultPresentationStrings.Calls_StartNewCall)
        XCTAssertTrue(resolved.button.traits.contains(.button))
    }
    
    func testResolvesMissedCallsEmptyStateText() {
        let resolved = CallListEmptyStateVoiceOver.resolve(strings: defaultPresentationStrings, isMissed: true)
        XCTAssertEqual(resolved.text, defaultPresentationStrings.Calls_NoMissedCallsPlacehoder)
    }
}

