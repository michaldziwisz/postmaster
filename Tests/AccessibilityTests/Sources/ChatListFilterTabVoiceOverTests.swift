import ChatListFilterTabContainerNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListFilterTabVoiceOverTests: XCTestCase {
    func testTabItemResolvesUnreadValue() {
        let resolved = ChatListFilterTabItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Work",
            unreadCount: 3,
            isSelected: false,
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, "Work")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Chat_UnreadMessages(3))
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testTabItemResolvesNilValueWhenUnreadCountIsZero() {
        let resolved = ChatListFilterTabItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "All Chats",
            unreadCount: 0,
            isSelected: false,
            isEnabled: true
        )
        XCTAssertNil(resolved.value)
    }
    
    func testTabItemSelectedTrait() {
        let resolved = ChatListFilterTabItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Work",
            unreadCount: 0,
            isSelected: true,
            isEnabled: true
        )
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testTabItemDisabledTraitWhenNotEnabled() {
        let resolved = ChatListFilterTabItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Work",
            unreadCount: 1,
            isSelected: false,
            isEnabled: false
        )
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testDeleteButtonResolvesLabelAndTabValue() {
        let resolved = ChatListFilterTabDeleteButtonVoiceOver.resolve(strings: defaultPresentationStrings, tabTitle: "Work")
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Delete)
        XCTAssertEqual(resolved.value, "Work")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

