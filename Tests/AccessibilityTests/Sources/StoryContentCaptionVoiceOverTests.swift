import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryContentCaptionVoiceOverTests: XCTestCase {
    func testResolveWithoutLinkIsStaticTextWithoutHint() {
        let resolved = StoryContentCaptionVoiceOver.resolve(
            strings: defaultPresentationStrings,
            text: "Caption",
            containsLink: false
        )
        
        XCTAssertEqual(resolved.label, "Caption")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
    }
    
    func testResolveWithLinkAddsOpenLinkHintAndLinkTrait() {
        let resolved = StoryContentCaptionVoiceOver.resolve(
            strings: defaultPresentationStrings,
            text: "Caption",
            containsLink: true
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
    }
    
    func testResolveTrimsWhitespace() {
        let resolved = StoryContentCaptionVoiceOver.resolve(
            strings: defaultPresentationStrings,
            text: "  Caption  ",
            containsLink: false
        )
        
        XCTAssertEqual(resolved.label, "Caption")
    }
}

