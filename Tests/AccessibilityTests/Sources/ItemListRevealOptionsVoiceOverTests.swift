import ItemListUI
import UIKit
import XCTest

final class ItemListRevealOptionsVoiceOverTests: XCTestCase {
    func testResolveCustomActionsRunsHandlerForEachOption() {
        var invokedKeys: [Int32] = []
        
        let left = [
            ItemListRevealOption(key: 1, title: "Left", icon: .none, color: .red, textColor: .white)
        ]
        let right = [
            ItemListRevealOption(key: 2, title: "Right", icon: .none, color: .blue, textColor: .white)
        ]
        
        let actions = ItemListRevealOptionsVoiceOver.resolveCustomActions(options: (left: left, right: right), perform: { option in
            invokedKeys.append(option.key)
            return option.key == 2
        })
        
        XCTAssertEqual(actions.map(\.name), ["Left", "Right"])
        XCTAssertFalse(actions[0].actionHandler?(actions[0]) ?? true)
        XCTAssertTrue(actions[1].actionHandler?(actions[1]) ?? false)
        XCTAssertEqual(invokedKeys, [1, 2])
    }
}
