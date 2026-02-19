import ChatListTitleView
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListTitleVoiceOverTests: XCTestCase {
    func testResolveWhenPasscodeNotSetIsHeaderOnly() {
        let resolved = ChatListTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            titleText: "Chats",
            isPasscodeSet: false,
            isManuallyLocked: false
        )
        
        XCTAssertEqual(resolved.label, "Chats")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
    
    func testResolveWhenPasscodeSetAndUnlockedIsHeaderButtonWithLockHint() {
        let resolved = ChatListTitleVoiceOver.resolve(
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
    
    func testResolveWhenPasscodeSetAndLockedUsesUnlockHint() {
        let resolved = ChatListTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            titleText: "Chats",
            isPasscodeSet: true,
            isManuallyLocked: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.DialogList_PasscodeUnlockHelp)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

