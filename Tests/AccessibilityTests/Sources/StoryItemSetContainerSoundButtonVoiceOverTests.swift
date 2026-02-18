import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerSoundButtonVoiceOverTests: XCTestCase {
    func testNotVideoResolvesNil() {
        let resolved = StoryItemSetContainerSoundButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isVideo: false,
            isSilentVideo: false,
            isMuted: false
        )
        XCTAssertNil(resolved)
    }
    
    func testSilentVideoResolvesNoSoundLabel() {
        let resolved = StoryItemSetContainerSoundButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isVideo: true,
            isSilentVideo: true,
            isMuted: true
        )
        XCTAssertEqual(resolved?.label, defaultPresentationStrings.Story_TooltipVideoHasNoSound)
        XCTAssertNil(resolved?.value)
        XCTAssertTrue(resolved?.traits.contains(.button) ?? false)
    }
    
    func testMutedVideoResolvesEnableSoundAndOffValue() {
        let resolved = StoryItemSetContainerSoundButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isVideo: true,
            isSilentVideo: false,
            isMuted: true
        )
        XCTAssertEqual(resolved?.label, defaultPresentationStrings.PeerInfo_EnableSound)
        XCTAssertEqual(resolved?.value, defaultPresentationStrings.VoiceOver_Common_Off)
    }
    
    func testUnmutedVideoResolvesDisableSoundAndOnValue() {
        let resolved = StoryItemSetContainerSoundButtonVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isVideo: true,
            isSilentVideo: false,
            isMuted: false
        )
        XCTAssertEqual(resolved?.label, defaultPresentationStrings.PeerInfo_DisableSound)
        XCTAssertEqual(resolved?.value, defaultPresentationStrings.VoiceOver_Common_On)
    }
}
