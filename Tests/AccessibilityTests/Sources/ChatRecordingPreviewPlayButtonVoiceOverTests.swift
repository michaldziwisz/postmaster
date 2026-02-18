import ChatRecordingPreviewInputPanelNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatRecordingPreviewPlayButtonVoiceOverTests: XCTestCase {
    func testResolveUsesPlayLabelWhenNotPlaying() {
        let resolved = ChatRecordingPreviewPlayButtonVoiceOver.resolve(strings: defaultPresentationStrings, isPlaying: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Media_PlaybackPlay)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.startsMediaSession))
    }
    
    func testResolveUsesPauseLabelWhenPlaying() {
        let resolved = ChatRecordingPreviewPlayButtonVoiceOver.resolve(strings: defaultPresentationStrings, isPlaying: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Media_PlaybackPause)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.startsMediaSession))
    }
}

