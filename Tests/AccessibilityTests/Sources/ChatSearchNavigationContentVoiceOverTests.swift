import ChatSearchNavigationContentNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatSearchNavigationContentVoiceOverTests: XCTestCase {
    func testResolveCloseButton() {
        let resolved = ChatSearchNavigationContentVoiceOver.resolveCloseButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveDisabledAddsNotEnabledTrait() {
        let resolved = ChatSearchNavigationContentVoiceOver.resolveCloseButton(strings: defaultPresentationStrings, isEnabled: false)
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

