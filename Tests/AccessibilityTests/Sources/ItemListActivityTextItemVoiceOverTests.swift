import Display
import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListActivityTextItemVoiceOverTests: XCTestCase {
    func testLinkTextIsExposedAsSingleAccessibleLinkElement() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        let item = ItemListActivityTextItem(
            displayActivity: false,
            presentationData: presentationData,
            text: "[Example](https://example.com)",
            color: .generic,
            linkAction: { _ in },
            sectionId: 0
        )
        
        let node = ItemListActivityTextItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply()
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let linkElement = elements.first(where: { ($0.accessibilityLabel ?? "").contains("Example") }) else {
            XCTFail("Expected a link accessibility element containing label 'Example'")
            return
        }
        
        XCTAssertTrue(linkElement.accessibilityTraits.contains(.link))
        XCTAssertEqual(linkElement.accessibilityHint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
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

