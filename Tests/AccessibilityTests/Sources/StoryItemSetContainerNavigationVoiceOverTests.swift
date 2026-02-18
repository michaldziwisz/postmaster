import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerNavigationVoiceOverTests: XCTestCase {
    func testZeroCountResolvesNilValue() {
        let resolved = StoryItemSetContainerNavigationVoiceOver.resolve(strings: defaultPresentationStrings, index: 0, count: 0)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_Guide_Title)
        XCTAssertNil(resolved.value)
        XCTAssertFalse(resolved.traits.contains(.adjustable))
    }
    
    func testSingleItemResolvesIndexWithoutAdjustable() {
        let resolved = StoryItemSetContainerNavigationVoiceOver.resolve(strings: defaultPresentationStrings, index: 0, count: 1)
        XCTAssertEqual(resolved.value, "1 of 1")
        XCTAssertFalse(resolved.traits.contains(.adjustable))
    }
    
    func testMultipleItemsResolvesAdjustableIndex() {
        let resolved = StoryItemSetContainerNavigationVoiceOver.resolve(strings: defaultPresentationStrings, index: 1, count: 3)
        XCTAssertEqual(resolved.value, "2 of 3")
        XCTAssertTrue(resolved.traits.contains(.adjustable))
    }
}
