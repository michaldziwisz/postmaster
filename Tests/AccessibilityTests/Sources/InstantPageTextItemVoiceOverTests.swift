import InstantPageUI
import TelegramPresentationData
import TextFormat
import UIKit
import XCTest

final class InstantPageTextItemVoiceOverTests: XCTestCase {
    func testResolveWithoutLinks() {
        let attributedText = NSAttributedString(string: "Hello")
        
        let resolved = InstantPageTextItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.label, "Hello")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
        XCTAssertTrue(resolved.linkActions.isEmpty)
    }
    
    func testResolveWithLinksAddsHintTraitsAndActions() {
        let attributedText = NSMutableAttributedString(string: "Desktop Web")
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        
        attributedText.addAttribute(urlKey, value: InstantPageUrlItem(url: "desktop", webpageId: nil), range: NSRange(location: 0, length: 7))
        attributedText.addAttribute(urlKey, value: InstantPageUrlItem(url: "web", webpageId: nil), range: NSRange(location: 8, length: 3))
        
        let resolved = InstantPageTextItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
        XCTAssertEqual(
            resolved.linkActions,
            [
                InstantPageTextItemVoiceOver.LinkAction(title: "Desktop", value: InstantPageUrlItem(url: "desktop", webpageId: nil)),
                InstantPageTextItemVoiceOver.LinkAction(title: "Web", value: InstantPageUrlItem(url: "web", webpageId: nil))
            ]
        )
    }
}

