import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetViewListOrderSelectorVoiceOverTests: XCTestCase {
    func testReactionsFirstResolvesLabelAndHintForViewerList() {
        let resolved = StoryItemSetViewListOrderSelectorVoiceOver.resolve(
            strings: defaultPresentationStrings,
            sortMode: .reactionsFirst,
            isChannel: false
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_ViewList_ContextSortReactions)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.Story_ViewList_ContextSortInfo)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testRepostsFirstResolvesHintForChannelList() {
        let resolved = StoryItemSetViewListOrderSelectorVoiceOver.resolve(
            strings: defaultPresentationStrings,
            sortMode: .repostsFirst,
            isChannel: true
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_ViewList_ContextSortReposts)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.Story_ViewList_ContextSortChannelInfo)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
