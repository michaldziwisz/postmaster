import ChatListTitleView
import TelegramCore
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListTitleStatusButtonVoiceOverTests: XCTestCase {
    func testResolvePremiumUsesSetEmojiStatusLabel() {
        let resolved = ChatListTitleStatusButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            status: .premium
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.PeerInfo_SetEmojiStatus)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveEmojiUsesChangeEmojiStatusLabel() {
        let emojiStatus = PeerEmojiStatus(content: .emoji(fileId: 123), expirationDate: nil)
        let resolved = ChatListTitleStatusButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            status: .emoji(emojiStatus)
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.PeerInfo_ChangeEmojiStatus)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

