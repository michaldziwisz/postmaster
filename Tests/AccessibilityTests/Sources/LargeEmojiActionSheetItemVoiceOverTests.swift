import TelegramUI
import UIKit
import XCTest

final class LargeEmojiActionSheetItemVoiceOverTests: XCTestCase {
    func testResolveTrimsLabelAndUsesButtonImageTraits() {
        let resolved = LargeEmojiActionSheetItemVoiceOver.resolve(text: " 😀 \n")
        
        XCTAssertEqual(resolved.label, "😀")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.image))
    }
}

