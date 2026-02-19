import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoScreenLabeledValueItemVoiceOverTests: XCTestCase {
    func testResolveQrCodeIconButtonUsesQrCodeTitleAndButtonTraits() {
        let resolved = PeerInfoScreenLabeledValueIconButtonVoiceOver.resolve(strings: defaultPresentationStrings, icon: .qrCode)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.PeerInfo_QRCode_Title)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolvePremiumGiftIconButtonUsesVoiceOverGiftPremiumLabel() {
        let resolved = PeerInfoScreenLabeledValueIconButtonVoiceOver.resolve(strings: defaultPresentationStrings, icon: .premiumGift)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_GiftPremium)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveExpandButtonIncludesRowLabelWhenNonEmpty() {
        let resolved = PeerInfoScreenLabeledValueExpandButtonVoiceOver.resolve(strings: defaultPresentationStrings, rowLabel: "Bio")
        XCTAssertEqual(resolved.label, "Bio, \(defaultPresentationStrings.PeerInfo_BioExpand)")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveExpandButtonUsesMoreTextWhenRowLabelEmpty() {
        let resolved = PeerInfoScreenLabeledValueExpandButtonVoiceOver.resolve(strings: defaultPresentationStrings, rowLabel: "")
        XCTAssertEqual(resolved.label, defaultPresentationStrings.PeerInfo_BioExpand)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

