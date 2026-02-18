import StoryFooterPanelComponent
import TelegramPresentationData
import UIKit
import XCTest

final class StoryFooterPanelViewStatsVoiceOverTests: XCTestCase {
    func testNoViewsLabelResolves() {
        let resolved = StoryFooterPanelViewStatsVoiceOver.resolve(strings: defaultPresentationStrings, viewCount: 0, isEnabled: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_Footer_NoViews)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testViewCountLabelResolvesAndDisabledIsNotEnabled() {
        let resolved = StoryFooterPanelViewStatsVoiceOver.resolve(strings: defaultPresentationStrings, viewCount: 3, isEnabled: false)
        
        var expected = defaultPresentationStrings.Story_Footer_ViewCount(3)
        if let range = expected.range(of: "|") {
            if let nextRange = expected.range(of: "|", range: range.upperBound ..< expected.endIndex) {
                expected.removeSubrange(expected.startIndex ..< nextRange.upperBound)
            }
        }
        
        XCTAssertEqual(resolved.label, expected)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}
