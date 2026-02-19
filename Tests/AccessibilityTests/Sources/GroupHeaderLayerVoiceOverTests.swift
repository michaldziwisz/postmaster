import EntityKeyboard
import TelegramPresentationData
import UIKit
import XCTest

final class GroupHeaderLayerVoiceOverTests: XCTestCase {
    func testResolveHeaderIncludesLockedValueWhenPremiumLocked() {
        let resolved = GroupHeaderLayerVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Pack",
            subtitle: nil,
            badge: nil,
            isPremiumLocked: true,
            hasClear: false,
            isStickers: false,
            isEmbedded: false
        )
        
        XCTAssertEqual(resolved.header.label, "Pack")
        XCTAssertEqual(resolved.header.value, defaultPresentationStrings.Intents_ErrorLockedTitle)
        XCTAssertTrue(resolved.header.traits.contains(.header))
        XCTAssertNil(resolved.clear)
    }
    
    func testResolveClearRecentEmojiLabel() {
        let resolved = GroupHeaderLayerVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: defaultPresentationStrings.Emoji_FrequentlyUsed,
            subtitle: nil,
            badge: nil,
            isPremiumLocked: false,
            hasClear: true,
            isStickers: false,
            isEmbedded: false
        )
        
        XCTAssertEqual(resolved.clear?.label, defaultPresentationStrings.Emoji_ClearRecent)
        XCTAssertTrue(resolved.clear?.traits.contains(.button) ?? false)
    }
    
    func testResolveClearRecentStickersLabel() {
        let resolved = GroupHeaderLayerVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: defaultPresentationStrings.Stickers_FrequentlyUsed,
            subtitle: nil,
            badge: nil,
            isPremiumLocked: false,
            hasClear: true,
            isStickers: true,
            isEmbedded: false
        )
        
        XCTAssertEqual(resolved.clear?.label, defaultPresentationStrings.Stickers_ClearRecent)
    }
    
    func testResolveEmbeddedClearUsesHideSectionFormat() {
        let resolved = GroupHeaderLayerVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "TRENDING",
            subtitle: nil,
            badge: nil,
            isPremiumLocked: false,
            hasClear: true,
            isStickers: false,
            isEmbedded: true
        )
        
        XCTAssertEqual(resolved.clear?.label, defaultPresentationStrings.VoiceOver_EmojiPager_HideSection("TRENDING").string)
    }
}

