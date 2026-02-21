import TelegramBaseController
import UIKit
import XCTest

final class AudioRateButtonBaseControllerAccessibilityTests: XCTestCase {
    func testAudioRateButtonIsAccessibilityElementWithButtonTrait() {
        let button = AudioRateButton()
        
        XCTAssertTrue(button.isAccessibilityElement)
        XCTAssertTrue(button.accessibilityTraits.contains(.button))
    }
}

