import AudioTranscriptionButtonComponent
import TelegramPresentationData
import UIKit
import XCTest

final class AudioTranscriptionButtonComponentVoiceOverTests: XCTestCase {
    func testResolveCollapsedIsButton() {
        let resolved = AudioTranscriptionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            state: .collapsed
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.GroupBoost_AudioTranscription)
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveInProgressUsesLoadingValueAndUpdatesFrequentlyTrait() {
        let resolved = AudioTranscriptionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            state: .inProgress
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Channel_NotificationLoading)
        XCTAssertTrue(resolved.traits.contains(.updatesFrequently))
    }
    
    func testResolveExpandedAddsSelectedTrait() {
        let resolved = AudioTranscriptionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            state: .expanded
        )
        
        XCTAssertTrue(resolved.traits.contains(.selected))
        if #available(iOS 17.0, *) {
            XCTAssertTrue(resolved.traits.contains(.toggleButton))
        }
    }
    
    func testResolveLockedUsesLockedValue() {
        let resolved = AudioTranscriptionButtonComponentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            state: .locked
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Intents_ErrorLockedTitle)
    }
}

