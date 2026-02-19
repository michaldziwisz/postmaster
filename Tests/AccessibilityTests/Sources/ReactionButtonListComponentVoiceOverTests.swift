import ReactionButtonListComponent
import TelegramCore
import TelegramPresentationData
import UIKit
import XCTest

final class ReactionButtonListComponentVoiceOverTests: XCTestCase {
    func testResolveBuiltinReactionUsesEmojiLabelAndCountValue() {
        let resolved = ReactionButtonListComponentVoiceOver.resolveReactionButton(
            strings: defaultPresentationStrings,
            reaction: .builtin("👍"),
            tagTitle: nil,
            customAlt: nil,
            count: 12,
            isSelected: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "👍")
        XCTAssertEqual(resolved.value, "12")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveCustomReactionPrefersAltLabel() {
        let resolved = ReactionButtonListComponentVoiceOver.resolveReactionButton(
            strings: defaultPresentationStrings,
            reaction: .custom(123),
            tagTitle: nil,
            customAlt: "💯",
            count: 3,
            isSelected: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "💯")
        XCTAssertEqual(resolved.value, "3")
    }
    
    func testResolveTagTitleOverridesLabel() {
        let resolved = ReactionButtonListComponentVoiceOver.resolveReactionButton(
            strings: defaultPresentationStrings,
            reaction: .builtin("👍"),
            tagTitle: "Work",
            customAlt: nil,
            count: 0,
            isSelected: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Work")
        XCTAssertNil(resolved.value)
    }
    
    func testResolveStarsUsesStarLabel() {
        let resolved = ReactionButtonListComponentVoiceOver.resolveReactionButton(
            strings: defaultPresentationStrings,
            reaction: .stars,
            tagTitle: nil,
            customAlt: nil,
            count: 1,
            isSelected: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "⭐️")
        XCTAssertEqual(resolved.value, "1")
    }
}

