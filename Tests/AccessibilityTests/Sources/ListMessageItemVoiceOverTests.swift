import ListMessageItem
import TelegramPresentationData
import UIKit
import XCTest

final class ListMessageItemVoiceOverTests: XCTestCase {
    func testResolveBasic() {
        let resolved = ListMessageItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            chatTitle: "Chat",
            authorName: nil,
            summary: "Hello",
            isSelected: false
        )
        
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, "Chat")
        XCTAssertEqual(resolved.value, "Hello")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveIncludesAuthorLine() {
        let resolved = ListMessageItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            chatTitle: "Chat",
            authorName: "Alice",
            summary: "Hello",
            isSelected: false
        )
        
        XCTAssertEqual(
            resolved.value,
            "\(defaultPresentationStrings.VoiceOver_ChatList_MessageFrom(\"Alice\").string)\nHello"
        )
    }
    
    func testResolveSelectedTrait() {
        let resolved = ListMessageItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            chatTitle: "Chat",
            authorName: nil,
            summary: "Hello",
            isSelected: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveEmptyChatTitleHidesElement() {
        let resolved = ListMessageItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            chatTitle: "",
            authorName: nil,
            summary: "Hello",
            isSelected: false
        )
        
        XCTAssertFalse(resolved.isAccessibilityElement)
    }
}

