import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoScreenSwitchItemVoiceOverTests: XCTestCase {
    func testResolveUnlockedUsesSwitchHintAndSelectedTraitWhenOn() {
        let resolved = PeerInfoScreenSwitchItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isOn: true,
            isLocked: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_On)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveLockedUsesOpenHint() {
        let resolved = PeerInfoScreenSwitchItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isOn: false,
            isLocked: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_Off)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveDisabledUsesStaticTextTraitAndNoHint() {
        let resolved = PeerInfoScreenSwitchItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isOn: true,
            isLocked: false,
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Common_On)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

