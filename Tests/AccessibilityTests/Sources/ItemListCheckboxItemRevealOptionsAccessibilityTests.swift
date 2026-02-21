import Display
import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListCheckboxItemRevealOptionsAccessibilityTests: XCTestCase {
    func testDeleteRevealOptionIsExposedAsCustomAction() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didDelete = false
        
        let item = ItemListCheckboxItem(
            presentationData: presentationData,
            title: "Deletable",
            style: .left,
            checked: false,
            enabled: false,
            zeroSeparatorInsets: false,
            sectionId: 0,
            action: {},
            deleteAction: { didDelete = true }
        )
        
        let node = ItemListCheckboxItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply()
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "Deletable" }) else {
            XCTFail("Expected an accessibility element with label: Deletable")
            return
        }
        
        let actions = row.accessibilityCustomActions
        XCTAssertEqual(actions?.count, 1)
        XCTAssertEqual(actions?.first?.name, presentationData.strings.Common_Delete)
        XCTAssertTrue(actions?.first.flatMap { $0.actionHandler?($0) } ?? false)
        XCTAssertTrue(didDelete)
    }
    
    private static func collectAccessibilityElements(in root: UIView) -> [UIView] {
        var result: [UIView] = []
        
        func visit(_ view: UIView) {
            if view.isHidden || view.alpha < 0.01 {
                return
            }
            if view.isAccessibilityElement {
                result.append(view)
                return
            }
            if view.accessibilityElementsHidden {
                return
            }
            for subview in view.subviews {
                visit(subview)
            }
        }
        
        visit(root)
        return result
    }
}
