import AuthorizationUI
import TelegramPresentationData
import UIKit
import XCTest

final class AuthorizationSequencePhoneEntryNoticeVoiceOverTests: XCTestCase {
    func testResolveWithoutLinkIsStaticTextWithoutHint() {
        let resolved = AuthorizationSequencePhoneEntryNoticeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            hasLink: false,
            isEnabled: false
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveWithLinkEnabledAddsLinkTraitAndHint() {
        let resolved = AuthorizationSequencePhoneEntryNoticeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            hasLink: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveWithLinkDisabledAddsNotEnabledAndOmitsHint() {
        let resolved = AuthorizationSequencePhoneEntryNoticeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            hasLink: true,
            isEnabled: false
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.link))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

