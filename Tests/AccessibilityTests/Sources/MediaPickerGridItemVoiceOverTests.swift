import MediaPickerUI
import TelegramPresentationData
import UIKit
import XCTest

final class MediaPickerGridItemVoiceOverTests: XCTestCase {
    func testResolveItemPhotoUsesLocalizedLabelAndOpenHint() {
        let resolved = MediaPickerGridItemVoiceOver.resolveItem(
            strings: defaultPresentationStrings,
            kind: .photo,
            creationDate: nil,
            isDownloading: false,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_Photo)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.image))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveItemVideoUsesLocalizedLabelAndCancelHintWhenDownloading() {
        let resolved = MediaPickerGridItemVoiceOver.resolveItem(
            strings: defaultPresentationStrings,
            kind: .video,
            creationDate: nil,
            isDownloading: true,
            isSelected: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_Video)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.Common_Cancel)
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveSelectionControlUsesSelectLabelAndSelectedTrait() {
        let resolved = MediaPickerGridItemVoiceOver.resolveSelectionControl(strings: defaultPresentationStrings, isSelected: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Select)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
}

