import HorizontalTabsComponent
import TelegramPresentationData
import UIKit
import XCTest

final class HorizontalTabsComponentTabVoiceOverTests: XCTestCase {
    func testResolveSelectedWithActions() {
        let resolved = HorizontalTabsComponentTabVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isSelected: true,
            hasContextAction: true,
            hasDeleteAction: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        XCTAssertEqual(
            resolved.customActions,
            [
                .more(name: defaultPresentationStrings.Common_More),
                .delete(name: defaultPresentationStrings.Common_Delete),
            ]
        )
    }
    
    func testResolveNotSelectedNoActions() {
        let resolved = HorizontalTabsComponentTabVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isSelected: false,
            hasContextAction: false,
            hasDeleteAction: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
        XCTAssertTrue(resolved.customActions.isEmpty)
    }
}

