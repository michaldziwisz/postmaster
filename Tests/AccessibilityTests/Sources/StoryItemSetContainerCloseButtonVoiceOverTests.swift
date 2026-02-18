import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerCloseButtonVoiceOverTests: XCTestCase {
    func testCloseButtonResolvesLabelAndTraits() {
        let resolved = StoryItemSetContainerCloseButtonVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
