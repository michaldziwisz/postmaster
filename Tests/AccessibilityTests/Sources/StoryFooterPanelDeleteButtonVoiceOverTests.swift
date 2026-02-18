import StoryFooterPanelComponent
import TelegramPresentationData
import UIKit
import XCTest

final class StoryFooterPanelDeleteButtonVoiceOverTests: XCTestCase {
    func testPendingResolvesCancel() {
        let resolved = StoryFooterPanelDeleteButtonVoiceOver.resolve(strings: defaultPresentationStrings, isPending: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Cancel)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testNonPendingResolvesDelete() {
        let resolved = StoryFooterPanelDeleteButtonVoiceOver.resolve(strings: defaultPresentationStrings, isPending: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Delete)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
