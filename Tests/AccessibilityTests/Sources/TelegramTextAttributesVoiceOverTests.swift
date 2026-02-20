import TextFormat
import TelegramCore
import XCTest

final class TelegramTextAttributesVoiceOverTests: XCTestCase {
    func testFirstActionReturnsNilForPlainText() {
        let attributedText = NSAttributedString(string: "Hello")
        XCTAssertNil(TelegramTextAttributesVoiceOver.firstAction(in: attributedText))
    }
    
    func testFirstActionReturnsUrlWithConcealedFalseWhenTextMatches() {
        let attributedText = NSMutableAttributedString(string: "telegram.org")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.URL), value: "telegram.org", range: NSRange(location: 0, length: 11))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .url(url: "telegram.org", concealed: false)
        )
    }
    
    func testFirstActionReturnsUrlWithConcealedTrueWhenTextDiffers() {
        let attributedText = NSMutableAttributedString(string: "telegram.org")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.URL), value: "https://telegram.org", range: NSRange(location: 0, length: 11))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .url(url: "https://telegram.org", concealed: true)
        )
    }
    
    func testFirstActionReturnsHashtag() {
        let attributedText = NSMutableAttributedString(string: "#tag")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag), value: TelegramHashtag(peerName: nil, hashtag: "tag"), range: NSRange(location: 0, length: 4))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .hashtag(nil, "tag")
        )
    }
    
    func testFirstActionReturnsBotCommand() {
        let attributedText = NSMutableAttributedString(string: "/start")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.BotCommand), value: "/start", range: NSRange(location: 0, length: 6))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .botCommand("/start")
        )
    }
    
    func testFirstActionReturnsTextMention() {
        let attributedText = NSMutableAttributedString(string: "@username")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerTextMention), value: "username", range: NSRange(location: 0, length: 9))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .textMention("username")
        )
    }
    
    func testFirstActionReturnsPeerMention() {
        let peerId = EnginePeer.Id(namespace: Namespaces.Peer.CloudUser, id: EnginePeer.Id.Id._internalFromInt64Value(1))
        let attributedText = NSMutableAttributedString(string: "@me")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerMention), value: TelegramPeerMention(peerId: peerId, mention: "@me"), range: NSRange(location: 0, length: 3))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .peerMention(peerId: peerId, mention: "@me")
        )
    }
    
    func testFirstActionReturnsTimecode() {
        let attributedText = NSMutableAttributedString(string: "0:12")
        attributedText.addAttribute(NSAttributedString.Key(rawValue: TelegramTextAttributes.Timecode), value: TelegramTimecode(time: 12.0, text: "0:12"), range: NSRange(location: 0, length: 4))
        
        XCTAssertEqual(
            TelegramTextAttributesVoiceOver.firstAction(in: attributedText),
            .timecode(12.0, "0:12")
        )
    }
}
