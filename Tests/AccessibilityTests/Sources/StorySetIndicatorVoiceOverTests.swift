import StorySetIndicatorComponent
import TelegramPresentationData
import UIKit
import XCTest

final class StorySetIndicatorVoiceOverTests: XCTestCase {
    func testLabelUsesStoryCountAndHasOpenHint() {
        let resolved = StorySetIndicatorVoiceOver.resolve(strings: defaultPresentationStrings, totalCount: 3)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Profile_AvatarStoryCount(3))
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Stories_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

