import Display
import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListActionItemAccessibilityActivationTests: XCTestCase {
    func testActivateRunsActionWhenEnabled() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didActivate = false
        
        let item = ItemListActionItem(
            presentationData: presentationData,
            title: "Do thing",
            kind: .generic,
            alignment: .natural,
            sectionId: 0,
            style: .blocks,
            action: { didActivate = true }
        )
        
        let node = ItemListActionItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply(false)
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "Do thing" }) else {
            XCTFail("Expected an accessibility element with label: Do thing")
            return
        }
        
        XCTAssertTrue(row.accessibilityTraits.contains(.button))
        XCTAssertTrue(row.accessibilityActivate())
        XCTAssertTrue(didActivate)
    }
    
    func testActivateDoesNotRunActionWhenDisabled() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didActivate = false
        
        let item = ItemListActionItem(
            presentationData: presentationData,
            title: "Disabled",
            kind: .disabled,
            alignment: .natural,
            sectionId: 0,
            style: .blocks,
            action: { didActivate = true }
        )
        
        let node = ItemListActionItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply(false)
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "Disabled" }) else {
            XCTFail("Expected an accessibility element with label: Disabled")
            return
        }
        
        XCTAssertTrue(row.accessibilityTraits.contains(.button))
        XCTAssertTrue(row.accessibilityTraits.contains(.notEnabled))
        XCTAssertFalse(row.accessibilityActivate())
        XCTAssertFalse(didActivate)
    }
    
    func testLongTapIsExposedAsCustomAction() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didLongActivate = false
        
        let item = ItemListActionItem(
            presentationData: presentationData,
            title: "With long press",
            kind: .generic,
            alignment: .natural,
            sectionId: 0,
            style: .blocks,
            action: {},
            longTapAction: { didLongActivate = true }
        )
        
        let node = ItemListActionItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply(false)
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "With long press" }) else {
            XCTFail("Expected an accessibility element with label: With long press")
            return
        }
        
        let customActions = row.accessibilityCustomActions
        XCTAssertEqual(customActions?.count, 1)
        XCTAssertEqual(customActions?.first?.name, defaultPresentationStrings.Common_More)
        
        XCTAssertTrue(customActions?.first?.actionHandler?() ?? false)
        XCTAssertTrue(didLongActivate)
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

