import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatBusinessLinkTitlePanelVoiceOverTests: XCTestCase {
    func testCopyButtonLabel() {
        let resolved = ChatBusinessLinkTitlePanelVoiceOver.resolveCopyButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.GroupInfo_InviteLink_CopyLink)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testShareButtonLabel() {
        let resolved = ChatBusinessLinkTitlePanelVoiceOver.resolveShareButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.GroupInfo_InviteLink_ShareLink)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testDisabledAddsNotEnabledTrait() {
        let resolved = ChatBusinessLinkTitlePanelVoiceOver.resolveCopyButton(strings: defaultPresentationStrings, isEnabled: false)
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

