import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerPeerButtonVoiceOverTests: XCTestCase {
    func testEnabledResolvesTitleAndOpenHint() {
        let resolved = StoryItemSetContainerPeerButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testDisabledResolvesNotEnabledTraitWithoutHint() {
        let resolved = StoryItemSetContainerPeerButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            isEnabled: false
        )
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}
