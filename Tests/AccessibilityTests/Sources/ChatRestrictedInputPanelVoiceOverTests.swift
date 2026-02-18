import TelegramUI
import UIKit
import XCTest

final class ChatRestrictedInputPanelVoiceOverTests: XCTestCase {
    func testResolveUsesStaticTextTraitWhenNotInteractive() {
        let resolved = ChatRestrictedInputPanelVoiceOver.resolve(label: "Restricted", subtitle: nil, isInteractive: false)
        XCTAssertEqual(resolved.label, "Restricted")
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
    
    func testResolveUsesButtonTraitWhenInteractive() {
        let resolved = ChatRestrictedInputPanelVoiceOver.resolve(label: "Boost to unrestrict", subtitle: "Slow mode: 0:12", isInteractive: true)
        XCTAssertEqual(resolved.label, "Boost to unrestrict")
        XCTAssertEqual(resolved.value, "Slow mode: 0:12")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.staticText))
    }
    
    func testResolveOmitsEmptySubtitleValue() {
        let resolved = ChatRestrictedInputPanelVoiceOver.resolve(label: "Restricted", subtitle: "", isInteractive: false)
        XCTAssertNil(resolved.value)
    }
}

