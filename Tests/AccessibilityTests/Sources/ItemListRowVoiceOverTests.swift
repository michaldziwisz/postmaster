import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListRowVoiceOverTests: XCTestCase {
    func testResolveOpenEnabledUsesButtonTraitAndOpenHint() {
        let resolved = ItemListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .open, isEnabled: true)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveOpenDisabledUsesNotEnabledTraitAndNoHint() {
        let resolved = ItemListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .open, isEnabled: false)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveStaticTextUsesStaticTextTrait() {
        let resolved = ItemListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .staticText, isEnabled: true)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

