import HorizontalPeerItem
import TelegramPresentationData
import UIKit
import XCTest

final class HorizontalPeerItemVoiceOverTests: XCTestCase {
    func testResolveUnreadValueAndHint() {
        let resolved = HorizontalPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "Alice",
            unreadCount: 3,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Chat_UnreadMessages(3))
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveSelectedTrait() {
        let resolved = HorizontalPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "Alice",
            unreadCount: nil,
            isSelected: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveZeroUnreadOmitsValue() {
        let resolved = HorizontalPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            peerTitle: "Alice",
            unreadCount: 0,
            isSelected: false
        )
        
        XCTAssertNil(resolved.value)
    }
}

