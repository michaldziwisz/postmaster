import GalleryUI
import TelegramPresentationData
import TextFormat
import UIKit
import XCTest

final class ChatItemGalleryFooterContentVoiceOverTests: XCTestCase {
    func testResolveWithoutActions() {
        let attributedText = NSAttributedString(string: "Hello")
        
        let resolved = ChatItemGalleryFooterContentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.label, "Hello")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
        XCTAssertNil(resolved.actionKind)
        XCTAssertTrue(resolved.linkActions.isEmpty)
    }
    
    func testResolveWithUrlsAddsHintTraitsAndActions() {
        let attributedText = NSMutableAttributedString(string: "Desktop Web")
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        
        attributedText.addAttribute(urlKey, value: "desktop", range: NSRange(location: 0, length: 7))
        attributedText.addAttribute(urlKey, value: "web", range: NSRange(location: 8, length: 3))
        
        let resolved = ChatItemGalleryFooterContentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
        XCTAssertEqual(resolved.actionKind, .url)
        XCTAssertEqual(
            resolved.linkActions,
            [
                ChatItemGalleryFooterContentVoiceOver.LinkAction(title: "Desktop", url: "desktop", index: 0),
                ChatItemGalleryFooterContentVoiceOver.LinkAction(title: "Web", url: "web", index: 8)
            ]
        )
    }
    
    func testResolveWithNonUrlActionUsesOpenHint() {
        let attributedText = NSMutableAttributedString(string: "#tag")
        let hashtagKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag)
        attributedText.addAttribute(hashtagKey, value: TelegramHashtag(peerName: nil, hashtag: "tag"), range: NSRange(location: 0, length: 4))
        
        let resolved = ChatItemGalleryFooterContentVoiceOver.resolve(
            strings: defaultPresentationStrings,
            attributedText: attributedText
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertFalse(resolved.traits.contains(.link))
        XCTAssertEqual(resolved.actionKind, .other)
        XCTAssertTrue(resolved.linkActions.isEmpty)
    }
}

