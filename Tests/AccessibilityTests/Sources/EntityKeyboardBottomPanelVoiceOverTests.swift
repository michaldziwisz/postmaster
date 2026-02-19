import EntityKeyboard
import TelegramPresentationData
import UIKit
import XCTest

final class EntityKeyboardBottomPanelVoiceOverTests: XCTestCase {
    func testResolveTabSelectedTraits() {
        let resolved = EntityKeyboardBottomPanelVoiceOver.resolveTab(isSelected: true)
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveTabNotSelectedTraits() {
        let resolved = EntityKeyboardBottomPanelVoiceOver.resolveTab(isSelected: false)
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveAccessorySwitchToKeyboardLabel() {
        let resolved = EntityKeyboardBottomPanelVoiceOver.resolveAccessoryButton(strings: defaultPresentationStrings, kind: .switchToKeyboard)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Keyboard)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveAccessoryAddImageLabel() {
        let resolved = EntityKeyboardBottomPanelVoiceOver.resolveAccessoryButton(strings: defaultPresentationStrings, kind: .addImage)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.MediaPicker_AddImage)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveAccessorySettingsLabel() {
        let resolved = EntityKeyboardBottomPanelVoiceOver.resolveAccessoryButton(strings: defaultPresentationStrings, kind: .settings)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Settings_Title)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveAccessoryDeleteBackwardsLabel() {
        let resolved = EntityKeyboardBottomPanelVoiceOver.resolveAccessoryButton(strings: defaultPresentationStrings, kind: .deleteBackwards)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Delete)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

