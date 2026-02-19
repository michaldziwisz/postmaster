import EntityKeyboard
import TelegramPresentationData
import UIKit
import XCTest

final class EmojiPagerContentItemVoiceOverTests: XCTestCase {
    func testResolveStaticEmojiUsesEmojiAsLabel() {
        let item = EmojiPagerContentComponent.Item(
            animationData: nil,
            content: .staticEmoji("😄"),
            itemFile: nil,
            subgroupId: nil,
            icon: .none,
            tintMode: .none
        )
        
        let resolved = EmojiPagerContentItemVoiceOver.resolve(strings: defaultPresentationStrings, item: item, isSelected: false)
        
        XCTAssertEqual(resolved.label, "😄")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveSelectedAddsSelectedTrait() {
        let item = EmojiPagerContentComponent.Item(
            animationData: nil,
            content: .staticEmoji("🔥"),
            itemFile: nil,
            subgroupId: nil,
            icon: .none,
            tintMode: .none
        )
        
        let resolved = EmojiPagerContentItemVoiceOver.resolve(strings: defaultPresentationStrings, item: item, isSelected: true)
        
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
}

