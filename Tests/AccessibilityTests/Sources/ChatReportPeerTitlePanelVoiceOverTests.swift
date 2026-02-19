import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatReportPeerTitlePanelVoiceOverTests: XCTestCase {
    func testResolveCloseButtonLabel() {
        let resolved = ChatReportPeerTitlePanelVoiceOver.resolveCloseButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveAdminInfoTrimsAndUsesOpenHint() {
        let resolved = ChatReportPeerTitlePanelVoiceOver.resolveAdminInfo(
            strings: defaultPresentationStrings,
            text: "  Request admin approval  ",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Request admin approval")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveAdminInfoDisabledAddsNotEnabledAndNoHint() {
        let resolved = ChatReportPeerTitlePanelVoiceOver.resolveAdminInfo(
            strings: defaultPresentationStrings,
            text: "Request admin approval",
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
}

