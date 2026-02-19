import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoScreenListRowVoiceOverTests: XCTestCase {
    func testOpenRowHasButtonTraitAndOpenHint() {
        let resolved = PeerInfoScreenListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .open, isEnabled: true)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }

    func testActionRowHasButtonTraitWithoutHint() {
        let resolved = PeerInfoScreenListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .action, isEnabled: true)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }

    func testDisabledRowIsNotEnabledButton() {
        let resolved = PeerInfoScreenListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .open, isEnabled: false)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }

    func testStaticTextRowHasStaticTextTrait() {
        let resolved = PeerInfoScreenListRowVoiceOver.resolve(strings: defaultPresentationStrings, kind: .staticText, isEnabled: true)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

