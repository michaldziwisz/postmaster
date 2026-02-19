import ChatMessageBubbleItemNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageBubbleItemNodeVoiceOverTests: XCTestCase {
    func testResolveAdCloseButton() {
        let resolved = ChatMessageBubbleItemNodeVoiceOver.resolveAdCloseButton(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

