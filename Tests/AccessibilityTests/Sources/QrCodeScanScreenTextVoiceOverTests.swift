import QrCodeUI
import TelegramPresentationData
import TextFormat
import UIKit
import XCTest

final class QrCodeScanScreenTextVoiceOverTests: XCTestCase {
    func testResolveWithoutLinks() {
        let attributedText = NSAttributedString(string: "Hello")
        
        let resolved = QrCodeScanScreenTextVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.label, "Hello")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
        XCTAssertTrue(resolved.linkActions.isEmpty)
    }
    
    func testResolveWithLinksAddsHintAndActions() {
        let attributedText = NSMutableAttributedString(string: "Desktop Web")
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        
        attributedText.addAttribute(urlKey, value: "desktop", range: NSRange(location: 0, length: 7))
        attributedText.addAttribute(urlKey, value: "web", range: NSRange(location: 8, length: 3))
        
        let resolved = QrCodeScanScreenTextVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
        XCTAssertEqual(
            resolved.linkActions,
            [
                QrCodeScanScreenTextVoiceOver.LinkAction(title: "Desktop", value: "desktop"),
                QrCodeScanScreenTextVoiceOver.LinkAction(title: "Web", value: "web")
            ]
        )
    }
}

