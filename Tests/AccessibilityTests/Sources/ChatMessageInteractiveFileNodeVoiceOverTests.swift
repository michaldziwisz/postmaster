import ChatMessageInteractiveFileNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageInteractiveFileNodeVoiceOverTests: XCTestCase {
    func testResolvePlaybackButtonPlayingUsesPauseLabel() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolvePlaybackButton(
            strings: defaultPresentationStrings,
            isPlaying: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Media_PlaybackPause)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.startsMediaSession))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolvePlaybackButtonPausedUsesPlayLabel() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolvePlaybackButton(
            strings: defaultPresentationStrings,
            isPlaying: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Media_PlaybackPlay)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.startsMediaSession))
    }
    
    func testResolvePlaybackButtonDisabledAddsNotEnabledTrait() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolvePlaybackButton(
            strings: defaultPresentationStrings,
            isPlaying: false,
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(ChatMessageInteractiveFileNodeVoiceOver.shouldActivate(isEnabled: false))
    }
    
    func testResolveDownloadButtonFetchingUsesCancelDownloadingLabel() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolveDownloadButton(
            strings: defaultPresentationStrings,
            isFetching: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.DownloadList_CancelDownloading)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.startsMediaSession))
    }
    
    func testResolveDownloadButtonRemoteUsesDownloadLabel() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolveDownloadButton(
            strings: defaultPresentationStrings,
            isFetching: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.WebBrowser_Download_Download)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveOpenButtonUsesOpenLabel() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolveOpenButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_LinkDialogOpen)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.startsMediaSession))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveOpenButtonDisabledAddsNotEnabledTrait() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolveOpenButton(
            strings: defaultPresentationStrings,
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveWaveformIsAdjustable() {
        let resolved = ChatMessageInteractiveFileNodeVoiceOver.resolveWaveform(
            label: "Timeline",
            timestamp: 61.0,
            duration: 120.0,
            isEnabled: true,
            isPlaying: false
        )
        
        XCTAssertEqual(resolved.label, "Timeline")
        XCTAssertEqual(resolved.value, "1:01")
        XCTAssertTrue(resolved.traits.contains(.adjustable))
    }
}
