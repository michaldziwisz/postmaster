import EntityKeyboard
import TelegramPresentationData
import UIKit
import XCTest

final class GifPagerContentItemVoiceOverTests: XCTestCase {
    func testResolveWithTitleUsesTitleAsLabelAndGifAsValue() {
        let resolved = GifPagerContentItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Cats",
            description: "Funny cat gif"
        )
        
        XCTAssertEqual(resolved.label, "Cats")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Message_Animation)
        XCTAssertEqual(resolved.hint, "Funny cat gif")
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveWithTitleOnlyOmitsHint() {
        let resolved = GifPagerContentItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Dogs",
            description: nil
        )
        
        XCTAssertEqual(resolved.label, "Dogs")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Message_Animation)
        XCTAssertNil(resolved.hint)
    }
    
    func testResolveWithDescriptionOnlyUsesGifAsLabelAndDescriptionAsValue() {
        let resolved = GifPagerContentItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: nil,
            description: "Via GIPHY"
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_Animation)
        XCTAssertEqual(resolved.value, "Via GIPHY")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveTrimsWhitespace() {
        let resolved = GifPagerContentItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "   ",
            description: "  Cool  "
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_Animation)
        XCTAssertEqual(resolved.value, "Cool")
        XCTAssertNil(resolved.hint)
    }
}
