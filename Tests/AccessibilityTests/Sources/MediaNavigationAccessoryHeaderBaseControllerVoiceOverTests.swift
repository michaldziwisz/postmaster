import TelegramBaseController
import TelegramPresentationData
import UIKit
import XCTest

final class MediaNavigationAccessoryHeaderBaseControllerVoiceOverTests: XCTestCase {
    func testResolveTitleAreaJoinsTitleAndSubtitle() {
        let resolved = MediaNavigationAccessoryHeaderVoiceOver.resolveTitleArea(
            strings: defaultPresentationStrings,
            title: "Track",
            subtitle: "Artist",
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Track. Artist")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveTitleAreaDisabledAddsNotEnabledAndOmitsHint() {
        let resolved = MediaNavigationAccessoryHeaderVoiceOver.resolveTitleArea(
            strings: defaultPresentationStrings,
            title: "Track",
            subtitle: "Artist",
            isEnabled: false
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

