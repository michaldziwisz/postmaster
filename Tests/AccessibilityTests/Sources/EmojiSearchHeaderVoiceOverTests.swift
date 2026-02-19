import EntityKeyboard
import TelegramPresentationData
import UIKit
import XCTest

final class EmojiSearchHeaderVoiceOverTests: XCTestCase {
    func testResolveWhenTextInputActiveHidesContainer() {
        let resolved = EmojiSearchHeaderVoiceOver.resolve(
            placeholder: "Search Emoji",
            canFocus: true,
            isTextInputActive: true,
            selectedCategoryTitle: nil,
            strings: defaultPresentationStrings
        )
        
        XCTAssertFalse(resolved.isAccessibilityElement)
        XCTAssertNil(resolved.label)
        XCTAssertNil(resolved.value)
        XCTAssertTrue(resolved.traits.isEmpty)
        XCTAssertTrue(resolved.customActions.isEmpty)
    }
    
    func testResolveInactiveShowsSearchFieldPlaceholder() {
        let resolved = EmojiSearchHeaderVoiceOver.resolve(
            placeholder: "Search Emoji",
            canFocus: true,
            isTextInputActive: false,
            selectedCategoryTitle: nil,
            strings: defaultPresentationStrings
        )
        
        XCTAssertTrue(resolved.isAccessibilityElement)
        XCTAssertEqual(resolved.label, "Search Emoji")
        XCTAssertNil(resolved.value)
        XCTAssertTrue(resolved.traits.contains(.searchField))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertTrue(resolved.customActions.isEmpty)
    }
    
    func testResolveInactiveWithCategoryAddsClearCategoryAction() {
        let resolved = EmojiSearchHeaderVoiceOver.resolve(
            placeholder: "Search Emoji",
            canFocus: true,
            isTextInputActive: false,
            selectedCategoryTitle: "Smileys & People",
            strings: defaultPresentationStrings
        )
        
        XCTAssertEqual(resolved.value, "Smileys & People")
        XCTAssertEqual(resolved.customActions, [
            EmojiSearchHeaderVoiceOver.CustomAction(
                kind: .clearCategory,
                name: defaultPresentationStrings.VoiceOver_EmojiSearch_ClearCategory
            )
        ])
    }
    
    func testResolveWhenCannotFocusMarksAsNotEnabled() {
        let resolved = EmojiSearchHeaderVoiceOver.resolve(
            placeholder: "Search Emoji",
            canFocus: false,
            isTextInputActive: false,
            selectedCategoryTitle: nil,
            strings: defaultPresentationStrings
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

