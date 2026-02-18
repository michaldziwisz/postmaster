import ItemListPeerActionItem
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListPeerActionItemVoiceOverTests: XCTestCase {
    func testResolvesButtonTraitsWhenEnabled() {
        let resolved = ItemListPeerActionItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Start New Call",
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, "Start New Call")
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolvesNotEnabledTraitWhenDisabled() {
        let resolved = ItemListPeerActionItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Start New Call",
            isEnabled: false
        )
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

