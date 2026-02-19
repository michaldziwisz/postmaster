import TelegramPresentationData
import UIKit
import VideoChatMicButtonComponent
import XCTest

final class VideoChatMicButtonComponentVoiceOverTests: XCTestCase {
    func testResolveConnectingIsNotEnabledAndStartsMediaSession() {
        let resolved = VideoChatMicButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            content: .connecting,
            isCompact: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceChat_Connecting)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertTrue(resolved.traits.contains(.startsMediaSession))
    }
    
    func testResolveUnmutedUsesMuteShortLabel() {
        let resolved = VideoChatMicButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            content: .unmuted(pushToTalk: false),
            isCompact: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceChat_MuteShort)
        XCTAssertTrue(resolved.traits.contains(.startsMediaSession))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveRaiseHandSetsHint() {
        let resolved = VideoChatMicButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            content: .raiseHand(isRaised: true),
            isCompact: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceChat_AskedToSpeak)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceChat_AskedToSpeakHelp)
        XCTAssertFalse(resolved.traits.contains(.startsMediaSession))
    }
    
    func testResolveCompactLowercasesLabel() {
        let resolved = VideoChatMicButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            content: .muted(forced: false),
            isCompact: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceChat_Unmute.lowercased())
    }
}

