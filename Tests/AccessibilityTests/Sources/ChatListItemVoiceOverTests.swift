import ChatListUI
import UIKit
import XCTest

final class ChatListItemVoiceOverTests: XCTestCase {
    func testLoadingItemsAreHiddenFromVoiceOver() {
        let resolved = ChatListItemVoiceOver.resolve(isLoading: true, isEditing: false, isSelected: false)
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertTrue(resolved.traits.isEmpty)
    }
    
    func testRegularItemIsButton() {
        let resolved = ChatListItemVoiceOver.resolve(isLoading: false, isEditing: false, isSelected: false)
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testEditingSelectedItemIsSelectedButton() {
        let resolved = ChatListItemVoiceOver.resolve(isLoading: false, isEditing: true, isSelected: true)
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
}

