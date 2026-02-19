import ChatMessageJoinedChannelBubbleContentNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageJoinedChannelBubbleContentNodeVoiceOverTests: XCTestCase {
    func testResolveToggleUsesSimilarChannelsLabel() {
        let resolved = ChatMessageJoinedChannelBubbleContentNodeVoiceOver.resolveToggle(
            strings: defaultPresentationStrings,
            isExpanded: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_SimilarChannels)
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveCloseButtonUsesCommonCloseLabel() {
        let resolved = ChatMessageJoinedChannelBubbleContentNodeVoiceOver.resolveCloseButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveChannelItemTrimsAndSetsValue() {
        let resolved = ChatMessageJoinedChannelBubbleContentNodeVoiceOver.resolveChannelItem(
            title: "  My Channel  ",
            subtitle: "  1K  ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "My Channel")
        XCTAssertEqual(resolved.value, "1K")
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

