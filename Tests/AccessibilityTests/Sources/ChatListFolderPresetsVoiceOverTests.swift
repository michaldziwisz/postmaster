import ChatListUI
import UIKit
import XCTest

final class ChatListFolderPresetsVoiceOverTests: XCTestCase {
    func testSuggestedPresetTraitsReflectEnabledState() {
        let enabled = ChatListFilterPresetListSuggestedItemVoiceOver.resolve(isEnabled: true)
        XCTAssertTrue(enabled.traits.contains(.button))
        XCTAssertFalse(enabled.traits.contains(.notEnabled))
        
        let disabled = ChatListFilterPresetListSuggestedItemVoiceOver.resolve(isEnabled: false)
        XCTAssertTrue(disabled.traits.contains(.button))
        XCTAssertTrue(disabled.traits.contains(.notEnabled))
    }
    
    func testPresetListItemLabelDoesNotContainExtraParenthesis() {
        let resolved = ChatListFilterPresetListItemVoiceOver.resolve(title: "Work", subtitle: "12 chats", isDisabled: false)
        XCTAssertEqual(resolved.label, "Work")
        XCTAssertEqual(resolved.value, "12 chats")
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testPresetListItemEmptySubtitleDoesNotSetValue() {
        let resolved = ChatListFilterPresetListItemVoiceOver.resolve(title: "Work", subtitle: "", isDisabled: false)
        XCTAssertNil(resolved.value)
    }
}

