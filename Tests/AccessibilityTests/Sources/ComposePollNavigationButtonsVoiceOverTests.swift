import ComposePollUI
import TelegramPresentationData
import UIKit
import XCTest

final class ComposePollNavigationButtonsVoiceOverTests: XCTestCase {
    func testResolveClose() {
        let resolved = ComposePollNavigationButtonsVoiceOver.resolveClose(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveDone() {
        let resolved = ComposePollNavigationButtonsVoiceOver.resolveDone(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Done)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

