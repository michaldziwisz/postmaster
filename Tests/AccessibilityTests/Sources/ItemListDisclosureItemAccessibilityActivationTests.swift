import Display
import ItemListUI
import TelegramPresentationData
import UIKit
import XCTest

final class ItemListDisclosureItemAccessibilityActivationTests: XCTestCase {
    func testActivateRunsActionWhenEnabled() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didActivate = false
        
        let item = ItemListDisclosureItem(
            presentationData: presentationData,
            title: "Open thing",
            label: "Details",
            sectionId: 0,
            style: .blocks,
            action: { didActivate = true }
        )
        
        let node = ItemListDisclosureItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply()
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "Open thing" }) else {
            XCTFail("Expected an accessibility element with label: Open thing")
            return
        }
        
        XCTAssertTrue(row.accessibilityTraits.contains(.button))
        XCTAssertEqual(row.accessibilityHint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(row.accessibilityActivate())
        XCTAssertTrue(didActivate)
    }
    
    func testActivateDoesNotRunActionWhenDisabled() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didActivate = false
        
        let item = ItemListDisclosureItem(
            presentationData: presentationData,
            title: "Disabled",
            enabled: false,
            label: "Details",
            sectionId: 0,
            style: .blocks,
            action: { didActivate = true }
        )
        
        let node = ItemListDisclosureItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply()
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "Disabled" }) else {
            XCTFail("Expected an accessibility element with label: Disabled")
            return
        }
        
        XCTAssertTrue(row.accessibilityTraits.contains(.button))
        XCTAssertTrue(row.accessibilityTraits.contains(.notEnabled))
        XCTAssertNil(row.accessibilityHint)
        XCTAssertFalse(row.accessibilityActivate())
        XCTAssertFalse(didActivate)
    }
    
    func testNoActionIsStaticText() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        
        let item = ItemListDisclosureItem(
            presentationData: presentationData,
            title: "Version",
            label: "1.0",
            sectionId: 0,
            style: .blocks,
            action: nil
        )
        
        let node = ItemListDisclosureItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply()
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let row = elements.first(where: { $0.accessibilityLabel == "Version" }) else {
            XCTFail("Expected an accessibility element with label: Version")
            return
        }
        
        XCTAssertTrue(row.accessibilityTraits.contains(.staticText))
        XCTAssertFalse(row.accessibilityTraits.contains(.button))
        XCTAssertNil(row.accessibilityHint)
        XCTAssertFalse(row.accessibilityActivate())
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

