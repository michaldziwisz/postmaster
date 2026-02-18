import StoryFooterPanelComponent
import TelegramPresentationData
import UIKit
import XCTest

final class StoryFooterPanelActionButtonsVoiceOverTests: XCTestCase {
    func testLikeResolvesReactionsLabel() {
        let resolved = StoryFooterPanelLikeButtonVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_ViewList_TitleReactions)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testForwardResolvesForwardLabel() {
        let resolved = StoryFooterPanelForwardButtonVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_MessageContextForward)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testRepostResolvesRepostStoryLabel() {
        let resolved = StoryFooterPanelRepostButtonVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Share_RepostStory)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
