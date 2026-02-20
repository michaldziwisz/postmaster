import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoScreenCommentItemVoiceOverTests: XCTestCase {
    func testResolveNoLinkIsStaticTextWithoutHint() {
        let resolved = PeerInfoScreenCommentItemVoiceOver.resolve(strings: defaultPresentationStrings, containsLink: false)
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
    }
    
    func testResolveWithLinkAddsLinkTraitAndOpenLinkHint() {
        let resolved = PeerInfoScreenCommentItemVoiceOver.resolve(strings: defaultPresentationStrings, containsLink: true)
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertTrue(resolved.traits.contains(.link))
    }
}

