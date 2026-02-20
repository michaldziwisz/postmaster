import ChatListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListEmptyNodeVoiceOverTests: XCTestCase {
    func testResolveWithDescription() {
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "Title", description: "Description"), "Title\nDescription")
    }
    
    func testResolveWithoutDescription() {
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "Title", description: nil), "Title")
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "Title", description: ""), "Title")
    }
    
    func testResolveTrimsWhitespace() {
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "  Title  ", description: "  Description  "), "Title\nDescription")
    }
    
    func testResolveAnimationUsesAnimatedStickerAndPlayHint() {
        let resolved = ChatListEmptyNodeVoiceOver.resolveAnimation(strings: defaultPresentationStrings)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_AnimatedSticker)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_PlayHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
