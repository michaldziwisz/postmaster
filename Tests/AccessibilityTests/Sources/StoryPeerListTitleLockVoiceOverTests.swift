import StoryPeerListComponent
import TelegramPresentationData
import UIKit
import XCTest

final class StoryPeerListTitleLockVoiceOverTests: XCTestCase {
    func testResolveUsesLockHintWhenUnlocked() {
        let resolved = StoryPeerListTitleLockVoiceOver.resolve(
            strings: defaultPresentationStrings,
            titleText: "Chats",
            isPasscodeSet: true,
            isManuallyLocked: false
        )
        
        XCTAssertEqual(resolved.label, "Chats")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.DialogList_PasscodeLockHelp)
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveUsesUnlockHintWhenLocked() {
        let resolved = StoryPeerListTitleLockVoiceOver.resolve(
            strings: defaultPresentationStrings,
            titleText: "Chats",
            isPasscodeSet: true,
            isManuallyLocked: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.DialogList_PasscodeUnlockHelp)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

