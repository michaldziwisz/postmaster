import PeerInfoUI
import TelegramPresentationData
import TextFormat
import UIKit
import XCTest

final class SecretChatKeyControllerNodeVoiceOverTests: XCTestCase {
    func testResolveWithoutUrl() {
        let attributedText = NSAttributedString(string: "Learn more")
        
        let resolved = SecretChatKeyControllerNodeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.label, "Learn more")
        XCTAssertNil(resolved.url)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
    }
    
    func testResolveWithUrlAddsHintAndLinkTrait() {
        let attributedText = NSMutableAttributedString(string: "telegram.org")
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        attributedText.addAttribute(urlKey, value: "https://telegram.org/faq#secret-chats", range: NSRange(location: 0, length: 11))
        
        let resolved = SecretChatKeyControllerNodeVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.url, "https://telegram.org/faq#secret-chats")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
    }
}

