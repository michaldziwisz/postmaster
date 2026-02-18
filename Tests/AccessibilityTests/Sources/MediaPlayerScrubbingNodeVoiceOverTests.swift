import UIKit
import UniversalMediaPlayer
import XCTest

final class MediaPlayerScrubbingNodeVoiceOverTests: XCTestCase {
    func testResolveFormatsTimestampAndSetsAdjustableTrait() {
        let resolved = MediaPlayerScrubbingNodeVoiceOver.resolve(
            label: "Timeline",
            timestamp: 61.0,
            duration: 120.0,
            isEnabled: true,
            isPlaying: false
        )
        XCTAssertEqual(resolved.label, "Timeline")
        XCTAssertEqual(resolved.value, "1:01")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.adjustable))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(resolved.traits.contains(.updatesFrequently))
    }
    
    func testResolveAddsUpdatesFrequentlyWhenPlaying() {
        let resolved = MediaPlayerScrubbingNodeVoiceOver.resolve(
            label: "Timeline",
            timestamp: 0.0,
            duration: 10.0,
            isEnabled: true,
            isPlaying: true
        )
        XCTAssertTrue(resolved.traits.contains(.updatesFrequently))
    }
    
    func testResolveAddsNotEnabledTraitWhenDisabled() {
        let resolved = MediaPlayerScrubbingNodeVoiceOver.resolve(
            label: "Timeline",
            timestamp: 0.0,
            duration: 10.0,
            isEnabled: false,
            isPlaying: false
        )
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testSeekStepIsOneSecondUpToOneMinute() {
        XCTAssertEqual(MediaPlayerScrubbingNodeVoiceOver.seekStep(duration: 60.0), 1.0)
        XCTAssertEqual(MediaPlayerScrubbingNodeVoiceOver.seekStep(duration: 30.0), 1.0)
    }
    
    func testSeekStepIsFiveSecondsAboveOneMinute() {
        XCTAssertEqual(MediaPlayerScrubbingNodeVoiceOver.seekStep(duration: 61.0), 5.0)
    }
    
    func testAdjustedTimestampClampsToDuration() {
        XCTAssertEqual(MediaPlayerScrubbingNodeVoiceOver.adjustedTimestamp(timestamp: 9.0, duration: 10.0, step: 5.0, direction: 1), 10.0)
        XCTAssertEqual(MediaPlayerScrubbingNodeVoiceOver.adjustedTimestamp(timestamp: 1.0, duration: 10.0, step: 5.0, direction: -1), 0.0)
    }
}

