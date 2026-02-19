import TelegramUI
import UIKit
import XCTest

final class ChatUnblockInputPanelVoiceOverTests: XCTestCase {
    func testResolveTrimsLabel() {
        let resolved = ChatUnblockInputPanelVoiceOver.resolve(label: "  Unblock  ", isEnabled: true)
        
        XCTAssertEqual(resolved.label, "Unblock")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveDisabledAddsNotEnabledTrait() {
        let resolved = ChatUnblockInputPanelVoiceOver.resolve(label: "Unblock", isEnabled: false)
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

