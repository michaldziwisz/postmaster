import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatSearchTitleAccessoryPanelVoiceOverTests: XCTestCase {
    func testResolvePromoUnlock() {
        let resolved = ChatSearchTitleAccessoryPanelVoiceOver.resolvePromo(strings: defaultPresentationStrings, isUnlock: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_TagsHeaderPanel_Unlock)
        XCTAssertNil(resolved.value)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolvePromoAddTagsIncludesSuffixValue() {
        let resolved = ChatSearchTitleAccessoryPanelVoiceOver.resolvePromo(strings: defaultPresentationStrings, isUnlock: false)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_TagsHeaderPanel_AddTags)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Chat_TagsHeaderPanel_AddTagsSuffix)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveItemPremiumUsesSwitchHint() {
        let resolved = ChatSearchTitleAccessoryPanelVoiceOver.resolveItem(
            strings: defaultPresentationStrings,
            title: "Important",
            reactionText: "😀",
            count: 12,
            isSelected: false,
            isPremium: true
        )
        
        XCTAssertEqual(resolved.label, "Important")
        XCTAssertEqual(resolved.value, "12")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveItemFallsBackToReactionText() {
        let resolved = ChatSearchTitleAccessoryPanelVoiceOver.resolveItem(
            strings: defaultPresentationStrings,
            title: nil,
            reactionText: "😀",
            count: 1,
            isSelected: false,
            isPremium: true
        )
        
        XCTAssertEqual(resolved.label, "😀")
        XCTAssertEqual(resolved.value, "1")
    }
    
    func testResolveItemSelectedAddsSelectedTrait() {
        let resolved = ChatSearchTitleAccessoryPanelVoiceOver.resolveItem(
            strings: defaultPresentationStrings,
            title: "Work",
            reactionText: nil,
            count: 3,
            isSelected: true,
            isPremium: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveItemNonPremiumUsesOpenHint() {
        let resolved = ChatSearchTitleAccessoryPanelVoiceOver.resolveItem(
            strings: defaultPresentationStrings,
            title: "Work",
            reactionText: "😀",
            count: 3,
            isSelected: false,
            isPremium: false
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
    }
    
    func testResolveItemCustomActionsPremiumWithTitleUsesEditLabel() {
        let actions = ChatSearchTitleAccessoryPanelVoiceOver.resolveItemCustomActions(
            strings: defaultPresentationStrings,
            hasTitle: true,
            isPremium: true
        )
        
        XCTAssertEqual(actions, [
            ChatSearchTitleAccessoryPanelVoiceOver.CustomAction(
                kind: .editTagTitle,
                name: defaultPresentationStrings.Chat_ReactionContextMenu_EditTagLabel
            )
        ])
    }
    
    func testResolveItemCustomActionsPremiumWithoutTitleUsesSetLabel() {
        let actions = ChatSearchTitleAccessoryPanelVoiceOver.resolveItemCustomActions(
            strings: defaultPresentationStrings,
            hasTitle: false,
            isPremium: true
        )
        
        XCTAssertEqual(actions, [
            ChatSearchTitleAccessoryPanelVoiceOver.CustomAction(
                kind: .editTagTitle,
                name: defaultPresentationStrings.Chat_ReactionContextMenu_SetTagLabel
            )
        ])
    }
    
    func testResolveItemCustomActionsNonPremiumIsEmpty() {
        let actions = ChatSearchTitleAccessoryPanelVoiceOver.resolveItemCustomActions(
            strings: defaultPresentationStrings,
            hasTitle: true,
            isPremium: false
        )
        
        XCTAssertTrue(actions.isEmpty)
    }
}

