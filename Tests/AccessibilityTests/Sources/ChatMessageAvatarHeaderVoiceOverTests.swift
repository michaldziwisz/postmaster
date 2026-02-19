import ChatMessageItemImpl
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageAvatarHeaderVoiceOverTests: XCTestCase {
    func testResolveUserEnabledUsesProfileHint() {
        let resolved = ChatMessageAvatarHeaderVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "Alice",
            peerKind: .user,
            isEnabled: true
        )
        
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertNil(resolved.value)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_Profile)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveChannelEnabledUsesChannelInfoHint() {
        let resolved = ChatMessageAvatarHeaderVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "My Channel",
            peerKind: .channel,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_ChannelInfo)
    }
    
    func testResolveDisabledAddsNotEnabledTraitAndNoHint() {
        let resolved = ChatMessageAvatarHeaderVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "Bob",
            peerKind: .user,
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
    
    func testResolveEmptyPeerTitleHidesElement() {
        let resolved = ChatMessageAvatarHeaderVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "   ",
            peerKind: .user,
            isEnabled: true
        )
        
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertNil(resolved.label)
    }
}
