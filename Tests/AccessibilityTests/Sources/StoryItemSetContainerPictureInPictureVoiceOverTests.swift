import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerPictureInPictureVoiceOverTests: XCTestCase {
    func testPictureInPictureResolvesLabelAndTraits() {
        let resolved = StoryItemSetContainerPictureInPictureVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Gallery_VoiceOver_PictureInPicture)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
