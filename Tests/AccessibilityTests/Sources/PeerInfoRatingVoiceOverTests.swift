import PeerInfoRatingComponent
import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoRatingVoiceOverTests: XCTestCase {
    func testPositiveRatingIsButtonWithLevelValueAndOpenHint() {
        let resolved = PeerInfoRatingVoiceOver.resolve(strings: defaultPresentationStrings, level: 2)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.ProfileLevelInfo_RatingTitle)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.ProfileLevelInfo_LevelIndex(Int32(2)))
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }

    func testNegativeRatingUsesNegativeValueString() {
        let resolved = PeerInfoRatingVoiceOver.resolve(strings: defaultPresentationStrings, level: -1)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.ProfileLevelInfo_RatingTitle)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.ProfileLevelInfo_NegativeRating)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

