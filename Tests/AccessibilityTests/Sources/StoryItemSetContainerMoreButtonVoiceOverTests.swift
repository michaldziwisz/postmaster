import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerMoreButtonVoiceOverTests: XCTestCase {
    func testMoreButtonResolvesLabelAndTraits() {
        let resolved = StoryItemSetContainerMoreButtonVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_More)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testMoreButtonWhenDisabledIsNotEnabled() {
        let resolved = StoryItemSetContainerMoreButtonVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: false)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}
