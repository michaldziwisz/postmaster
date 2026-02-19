import TelegramUI
import UIKit
import XCTest

final class ChatToastAlertPanelVoiceOverTests: XCTestCase {
    func testResolveTrimsTextAndSetsStaticTextTrait() {
        let resolved = ChatToastAlertPanelVoiceOver.resolve(text: "  Toast message  ")
        
        XCTAssertEqual(resolved.label, "Toast message")
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

