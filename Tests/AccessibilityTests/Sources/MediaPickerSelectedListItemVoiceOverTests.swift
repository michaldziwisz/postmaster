import MediaPickerUI
import TelegramPresentationData
import UIKit
import XCTest

final class MediaPickerSelectedListItemVoiceOverTests: XCTestCase {
    func testResolvePhotoSelectedHasOpenHintAndDeleteAction() {
        let resolved = MediaPickerSelectedListItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            kind: .photo,
            creationDate: nil,
            isSelected: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_Photo)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.image))
        XCTAssertTrue(resolved.traits.contains(.selected))
        
        XCTAssertEqual(resolved.customActions.count, 1)
        XCTAssertEqual(resolved.customActions[0].kind, .delete)
        XCTAssertEqual(resolved.customActions[0].name, defaultPresentationStrings.Common_Delete)
    }
    
    func testResolveSelectionControlAddsSelectedTrait() {
        let resolved = MediaPickerSelectedListItemVoiceOver.resolveSelectionControl(strings: defaultPresentationStrings, isSelected: true)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_Select)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
}

