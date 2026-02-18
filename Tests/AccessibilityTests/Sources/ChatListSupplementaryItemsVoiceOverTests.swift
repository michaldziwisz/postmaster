import ChatListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListSupplementaryItemsVoiceOverTests: XCTestCase {
    func testAdditionalCategoryItemSelectedTrait() {
        let selected = ChatListAdditionalCategoryItemVoiceOver.resolve(isSelected: true)
        XCTAssertTrue(selected.traits.contains(.button))
        XCTAssertTrue(selected.traits.contains(.selected))
        
        let unselected = ChatListAdditionalCategoryItemVoiceOver.resolve(isSelected: false)
        XCTAssertTrue(unselected.traits.contains(.button))
        XCTAssertFalse(unselected.traits.contains(.selected))
    }
    
    func testFilterPresetCategoryItemExposesDeleteCustomActionName() {
        let resolved = ChatListFilterPresetCategoryItemVoiceOver.resolve(strings: defaultPresentationStrings)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertEqual(resolved.deleteActionName, defaultPresentationStrings.Common_Delete)
    }
}

