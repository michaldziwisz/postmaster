import ChatQrCodeScreen
import TelegramPresentationData
import UIKit
import XCTest

final class ChatQrCodeScreenNavigationButtonsVoiceOverTests: XCTestCase {
    func testResolveClose() {
        let resolved = ChatQrCodeScreenNavigationButtonsVoiceOver.resolveClose(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Close)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveSwitchAppearanceWhenLight() {
        let resolved = ChatQrCodeScreenNavigationButtonsVoiceOver.resolveSwitchAppearance(strings: defaultPresentationStrings, isDarkAppearance: false)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_Theme_SwitchToDark)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveSwitchAppearanceWhenDark() {
        let resolved = ChatQrCodeScreenNavigationButtonsVoiceOver.resolveSwitchAppearance(strings: defaultPresentationStrings, isDarkAppearance: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_Theme_SwitchToLight)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

