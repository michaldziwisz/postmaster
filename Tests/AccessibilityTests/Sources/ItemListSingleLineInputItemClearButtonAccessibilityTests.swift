import Display
import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListSingleLineInputItemClearButtonAccessibilityTests: XCTestCase {
    func testClearButtonIsAccessibleWhenVisible() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        
        let item = ItemListSingleLineInputItem(
            presentationData: presentationData,
            title: NSAttributedString(string: "Name"),
            text: "John",
            placeholder: "Name",
            clearType: .always,
            sectionId: 0,
            textUpdated: { _ in },
            action: {},
            cleared: nil
        )
        
        let node = ItemListSingleLineInputItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply()
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        let clearButtonLabel = defaultPresentationStrings.VoiceOver_Editing_ClearText
        
        guard let clearButton = elements.first(where: { $0.accessibilityLabel == clearButtonLabel }) else {
            XCTFail("Expected a clear button accessibility element with label: \(clearButtonLabel)")
            return
        }
        
        XCTAssertTrue(clearButton.accessibilityTraits.contains(.button))
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

