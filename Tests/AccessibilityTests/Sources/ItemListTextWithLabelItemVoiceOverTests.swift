import Display
import ItemListUI
import TelegramPresentationData
import TextFormat
import UIKit
import XCTest

final class ItemListTextWithLabelItemVoiceOverTests: XCTestCase {
    func testLinkOnlyItemIsActivatableAndExposedAsLink() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didOpen = false
        
        let item = ItemListTextWithLabelItem(
            presentationData: presentationData,
            label: "Terms",
            text: "https://example.com",
            enabledEntityTypes: [.allUrl],
            multiline: false,
            sectionId: 0,
            action: nil,
            linkItemAction: { action, link in
                if action == .tap, case .url = link {
                    didOpen = true
                }
            }
        )
        
        let node = ItemListTextWithLabelItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply(.None)
        
        XCTAssertTrue(node.accessibilityTraits.contains(.link))
        XCTAssertEqual(node.accessibilityHint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(node.accessibilityActivate())
        XCTAssertTrue(didOpen)
    }
    
    func testActionItemUsesOpenHintAndIsActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        let presentationData = ItemListPresentationData(defaultPresentationData())
        var didAct = false
        
        let item = ItemListTextWithLabelItem(
            presentationData: presentationData,
            label: "Account",
            text: "Details",
            enabledEntityTypes: [],
            multiline: false,
            sectionId: 0,
            action: { didAct = true }
        )
        
        let node = ItemListTextWithLabelItemNode()
        let params = ListViewItemLayoutParams(width: 320.0, leftInset: 16.0, rightInset: 16.0, availableHeight: 1000.0)
        let neighbors = itemListNeighbors(item: item, topItem: nil, bottomItem: nil)
        
        let (layout, apply) = node.asyncLayout()(item, params, neighbors)
        node.contentSize = layout.contentSize
        node.insets = layout.insets
        apply(.None)
        
        XCTAssertTrue(node.accessibilityTraits.contains(.button))
        XCTAssertEqual(node.accessibilityHint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(node.accessibilityActivate())
        XCTAssertTrue(didAct)
    }
}

