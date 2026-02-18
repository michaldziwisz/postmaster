import PeerListItemComponent
import TelegramPresentationData
import UIKit
import XCTest

final class PeerListItemVoiceOverTests: XCTestCase {
    func testResolvesLabelValueHintAndTraitsForEnabledRow() {
        let resolved = PeerListItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            subtitle: "Yesterday at 10:00",
            selectionState: .none,
            rightAccessory: .none,
            isEnabled: true,
            hasAction: true
        )
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.value, "Yesterday at 10:00")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolvesSelectedTraitForEditingSelection() {
        let resolved = PeerListItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            subtitle: "Online",
            selectionState: .editing(isSelected: true, isTinted: false),
            rightAccessory: .none,
            isEnabled: true,
            hasAction: true
        )
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolvesSelectedTraitForRightCheckAccessory() {
        let resolved = PeerListItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            subtitle: nil,
            selectionState: .none,
            rightAccessory: .check,
            isEnabled: true,
            hasAction: true
        )
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolvesNotEnabledTraitWhenRowIsDisabled() {
        let resolved = PeerListItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            subtitle: "",
            selectionState: .none,
            rightAccessory: .none,
            isEnabled: false,
            hasAction: true
        )
        XCTAssertNil(resolved.value)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

