import ContactsPeerItem
import TelegramPresentationData
import UIKit
import XCTest

final class ContactsPeerItemVoiceOverTests: XCTestCase {
    func testResolveTraitsEnabledButton() {
        let resolved = ContactsPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: true,
            isSelected: false,
            buttonActionTitle: nil,
            isDeletable: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertTrue(resolved.customActions.isEmpty)
    }
    
    func testResolveTraitsDisabledAddsNotEnabled() {
        let resolved = ContactsPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: false,
            isSelected: false,
            buttonActionTitle: nil,
            isDeletable: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveSelectedAddsSelectedTrait() {
        let resolved = ContactsPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: true,
            isSelected: true,
            buttonActionTitle: nil,
            isDeletable: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
    
    func testResolveCustomActionsIncludesButtonAndDelete() {
        let resolved = ContactsPeerItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isEnabled: true,
            isSelected: false,
            buttonActionTitle: defaultPresentationStrings.ChatList_Search_Open,
            isDeletable: true
        )
        
        XCTAssertEqual(
            resolved.customActions,
            [
                .buttonAction(name: defaultPresentationStrings.ChatList_Search_Open),
                .delete(name: defaultPresentationStrings.Common_Delete),
            ]
        )
    }
}

