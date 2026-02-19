import TelegramUI
import UIKit
import XCTest

final class ChatMessageActionSheetVoiceOverTests: XCTestCase {
    func testResolveActionButtonTrimsTitleAndSetsButtonTrait() {
        let resolved = ChatMessageActionSheetVoiceOver.resolveActionButton(title: "  Copy  ", isEnabled: true)
        
        XCTAssertEqual(resolved.label, "Copy")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
}

