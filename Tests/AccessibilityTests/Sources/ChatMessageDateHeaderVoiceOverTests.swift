import ChatMessageItemImpl
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageDateHeaderVoiceOverTests: XCTestCase {
    func testResolveEnabledAddsButtonTraitAndHint() {
        let resolved = ChatMessageDateHeaderVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Today",
            isActionEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Today")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.Chat_JumpToDate)
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveDisabledIsHeaderOnly() {
        let resolved = ChatMessageDateHeaderVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Yesterday",
            isActionEnabled: false
        )
        
        XCTAssertEqual(resolved.label, "Yesterday")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}
