import EntityKeyboard
import TelegramPresentationData
import UIKit
import XCTest

final class EntityKeyboardTopPanelVoiceOverTests: XCTestCase {
    func testResolveItemSelectedTraits() {
        let resolved = EntityKeyboardTopPanelVoiceOver.resolveItem(label: "Test", isSelected: true)
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertEqual(resolved.label, "Test")
        XCTAssertNil(resolved.hint)
    }
    
    func testResolveStaticEmojiSegmentUsesLabelsFromStrings() {
        let resolved = EntityKeyboardTopPanelVoiceOver.resolveStaticEmojiSegment(
            strings: defaultPresentationStrings,
            segment: .animalsAndNature,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_EmojiCategory_AnimalsAndNature)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertNil(resolved.hint)
    }
}

