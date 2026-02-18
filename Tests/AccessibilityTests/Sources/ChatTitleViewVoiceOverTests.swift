import ChatTitleView
import TelegramPresentationData
import UIKit
import XCTest

final class ChatTitleViewVoiceOverTests: XCTestCase {
    func testEnabledUserTitleIsHeaderButtonWithProfileHint() {
        let resolved = ChatTitleViewVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: true, peerKind: .user)
        
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_Profile)
    }
    
    func testEnabledGroupTitleHasGroupInfoHint() {
        let resolved = ChatTitleViewVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: true, peerKind: .group)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_GroupInfo)
    }
    
    func testEnabledChannelTitleHasChannelInfoHint() {
        let resolved = ChatTitleViewVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: true, peerKind: .channel)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_ChannelInfo)
    }
    
    func testDisabledTitleIsNotEnabledHeaderWithoutHint() {
        let resolved = ChatTitleViewVoiceOver.resolve(strings: defaultPresentationStrings, isEnabled: false, peerKind: .user)
        
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertFalse(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
}

