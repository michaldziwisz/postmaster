import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoHeaderTitleVoiceOverTests: XCTestCase {
    func testResolvePremiumAddsPremiumValueAndCustomAction() {
        let resolved = PeerInfoHeaderTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            credibility: .premium,
            hasEmojiStatus: false,
            hasUniqueGift: false
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Premium_Title)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertTrue(resolved.traits.contains(.header))
        XCTAssertEqual(resolved.customActions, [
            .init(name: defaultPresentationStrings.Premium_Title, kind: .showPremiumIntro)
        ])
    }
    
    func testResolveScamUsesScamValueWithoutCustomActions() {
        let resolved = PeerInfoHeaderTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            credibility: .scam,
            hasEmojiStatus: false,
            hasUniqueGift: false
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Message_ScamAccount)
        XCTAssertTrue(resolved.customActions.isEmpty)
    }
    
    func testResolveVerifiedUsesFallbackVerifiedValue() {
        let resolved = PeerInfoHeaderTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            credibility: .verified,
            hasEmojiStatus: false,
            hasUniqueGift: false
        )
        
        XCTAssertEqual(resolved.value, "Verified")
        XCTAssertTrue(resolved.customActions.isEmpty)
    }
    
    func testResolveEmojiStatusAddsEmojiStatusValueAndAction() {
        let resolved = PeerInfoHeaderTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            credibility: .none,
            hasEmojiStatus: true,
            hasUniqueGift: false
        )
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Premium_EmojiStatus)
        XCTAssertEqual(resolved.customActions, [
            .init(name: defaultPresentationStrings.Premium_EmojiStatus, kind: .showEmojiStatusIntro)
        ])
    }
    
    func testResolveUniqueGiftUsesViewUpgradedGiftAction() {
        let resolved = PeerInfoHeaderTitleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            credibility: .none,
            hasEmojiStatus: true,
            hasUniqueGift: true
        )
        
        XCTAssertEqual(resolved.customActions, [
            .init(name: defaultPresentationStrings.Gift_View_ViewUpgraded, kind: .openUniqueGift)
        ])
    }
}

