import MediaPlaybackHeaderPanelComponent
import UIKit
import XCTest

final class AudioRateButtonAccessibilityTests: XCTestCase {
    func testAudioRateButtonIsAccessibilityElementWithButtonTrait() {
        let button = AudioRateButton()
        
        XCTAssertTrue(button.isAccessibilityElement)
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
    }
}

