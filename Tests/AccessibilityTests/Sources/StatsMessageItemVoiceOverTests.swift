import StatisticsUI
import TelegramPresentationData
import UIKit
import XCTest

final class StatsMessageItemVoiceOverTests: XCTestCase {
    func testResolveEnabledIncludesHintAndButtonTrait() {
        let resolved = StatsMessageItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Hello",
            date: "Feb 19",
            views: "10 views",
            reactionsValue: "0",
            publicSharesValue: "2",
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, "Hello")
        XCTAssertEqual(resolved.value, "Feb 19, 10 views, Reactions: 0, Public Shares: 2")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveDisabledUsesStaticTextAndNoHint() {
        let resolved = StatsMessageItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Hello",
            date: "Feb 19",
            views: "No views",
            reactionsValue: "0",
            publicSharesValue: "0",
            isEnabled: false
        )
        XCTAssertEqual(resolved.hint, nil)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}

