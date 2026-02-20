import TelegramPresentationData
import TelegramUpdateUI
import UIKit
import XCTest

final class UpdateInfoItemVoiceOverTests: XCTestCase {
    func testResolveWithoutLinkUsesStaticTextTraitsAndNoHint() {
        let resolved = UpdateInfoItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Version 1.0",
            text: "Bug fixes",
            containsLink: false
        )
        
        XCTAssertEqual(resolved.label, "Version 1.0. Bug fixes")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
    }
    
    func testResolveWithLinkAddsLinkTraitAndHint() {
        let resolved = UpdateInfoItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Version 1.0",
            text: "Read more",
            containsLink: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
    }
}

