import MediaScrubberComponent
import TelegramPresentationData
import UIKit
import XCTest

final class TrimViewHandleVoiceOverTests: XCTestCase {
    func testResolveStartHandleUsesStartTimeLabelAndAdjustableTrait() {
        let resolved = TrimViewHandleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            handle: .start,
            position: 12.0,
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.BusinessMessageSetup_ScheduleStartTime)
        XCTAssertEqual(resolved.value, "0:12")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.adjustable))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveEndHandleUsesEndTimeLabel() {
        let resolved = TrimViewHandleVoiceOver.resolve(
            strings: defaultPresentationStrings,
            handle: .end,
            position: 61.0,
            isEnabled: true
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.BusinessMessageSetup_ScheduleEndTime)
        XCTAssertEqual(resolved.value, "1:01")
    }
    
    func testAdjustRangeStartHandleIncrementIncreasesStart() {
        let updated = TrimViewHandleVoiceOver.adjustRange(
            handle: .start,
            startPosition: 0.0,
            endPosition: 10.0,
            duration: 10.0,
            minDuration: 1.0,
            maxDuration: 10.0,
            step: 1.0,
            direction: 1
        )
        XCTAssertEqual(updated.startPosition, 1.0)
        XCTAssertEqual(updated.endPosition, 10.0)
    }
    
    func testAdjustRangeStartHandleDecrementRespectsMaxDurationByReducingEnd() {
        let updated = TrimViewHandleVoiceOver.adjustRange(
            handle: .start,
            startPosition: 10.0,
            endPosition: 18.0,
            duration: 20.0,
            minDuration: 1.0,
            maxDuration: 8.0,
            step: 1.0,
            direction: -1
        )
        XCTAssertEqual(updated.startPosition, 9.0)
        XCTAssertEqual(updated.endPosition, 17.0)
    }
    
    func testAdjustRangeEndHandleIncrementRespectsMaxDurationByIncreasingStart() {
        let updated = TrimViewHandleVoiceOver.adjustRange(
            handle: .end,
            startPosition: 10.0,
            endPosition: 18.0,
            duration: 20.0,
            minDuration: 1.0,
            maxDuration: 8.0,
            step: 1.0,
            direction: 1
        )
        XCTAssertEqual(updated.startPosition, 11.0)
        XCTAssertEqual(updated.endPosition, 19.0)
    }
}

