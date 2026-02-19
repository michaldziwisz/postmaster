import CameraScreen
import TelegramPresentationData
import UIKit
import XCTest

final class CameraFlashTintVoiceOverTests: XCTestCase {
    func testResolveSliderUsesLabelHintAndAdjustableTrait() {
        let resolved = CameraFlashTintVoiceOver.resolveSlider(strings: defaultPresentationStrings, value: 0.5)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Camera_FlashTintSize)
        XCTAssertEqual(resolved.value, "50%")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Camera_FlashTintSizeHint)
        XCTAssertTrue(resolved.traits.contains(.adjustable))
    }
    
    func testResolveSwatchIncludesLabelValueAndSelectedTrait() {
        let resolved = CameraFlashTintVoiceOver.resolveSwatch(strings: defaultPresentationStrings, swatch: .yellow, isSelected: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Camera_FlashTint)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.WallpaperSearch_ColorYellow)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveSwatchBlueUsesBlueColorString() {
        let resolved = CameraFlashTintVoiceOver.resolveSwatch(strings: defaultPresentationStrings, swatch: .blue, isSelected: false)
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.WallpaperSearch_ColorBlue)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
}

