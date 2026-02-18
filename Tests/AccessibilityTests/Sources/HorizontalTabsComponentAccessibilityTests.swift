import ComponentFlow
import HorizontalTabsComponent
import TelegramPresentationData
import UIKit
import XCTest

final class HorizontalTabsComponentAccessibilityTests: XCTestCase {
    func testTabsAreAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivateAll = false
        var didActivateUnread = false
        
        let allId = AnyHashable(0)
        let unreadId = AnyHashable(1)
        
        let tabs: [HorizontalTabsComponent.Tab] = [
            HorizontalTabsComponent.Tab(
                id: allId,
                content: .title(.init(text: "All", entities: [], enableAnimations: false)),
                badge: nil,
                action: { didActivateAll = true },
                contextAction: nil,
                deleteAction: nil
            ),
            HorizontalTabsComponent.Tab(
                id: unreadId,
                content: .title(.init(text: "Unread", entities: [], enableAnimations: false)),
                badge: .init(title: "3", isAccent: true),
                action: { didActivateUnread = true },
                contextAction: nil,
                deleteAction: nil
            ),
        ]
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(HorizontalTabsComponent(
                context: nil,
                theme: defaultPresentationTheme,
                tabs: tabs,
                selectedTab: allId,
                isEditing: false,
                layout: .fit
            )),
            environment: {},
            containerSize: CGSize(width: 320.0, height: 44.0)
        )
        
        guard let tabsView = componentView.view as? HorizontalTabsComponent.View else {
            XCTFail("Expected HorizontalTabsComponent.View")
            return
        }
        
        var elements = Self.collectAccessibilityElements(in: tabsView)
        XCTAssertEqual(elements.count, 2)
        
        let allElements = elements.filter { $0.accessibilityLabel == "All" }
        XCTAssertEqual(allElements.count, 1)
        
        let unreadElements = elements.filter { $0.accessibilityLabel == "Unread" }
        XCTAssertEqual(unreadElements.count, 1)
        
        let allElement = allElements[0]
        XCTAssertTrue(allElement.isAccessibilityElement)
        XCTAssertTrue(allElement.accessibilityTraits.contains(.button))
        XCTAssertTrue(allElement.accessibilityTraits.contains(.selected))
        
        let unreadElement = unreadElements[0]
        XCTAssertTrue(unreadElement.accessibilityTraits.contains(.button))
        XCTAssertFalse(unreadElement.accessibilityTraits.contains(.selected))
        XCTAssertEqual(unreadElement.accessibilityValue, "3")
        
        XCTAssertTrue(unreadElement.accessibilityActivate())
        XCTAssertFalse(didActivateAll)
        XCTAssertTrue(didActivateUnread)
        
        didActivateAll = false
        didActivateUnread = false
        
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(HorizontalTabsComponent(
                context: nil,
                theme: defaultPresentationTheme,
                tabs: tabs,
                selectedTab: unreadId,
                isEditing: false,
                layout: .fit
            )),
            environment: {},
            containerSize: CGSize(width: 320.0, height: 44.0)
        )
        
        guard let tabsView2 = componentView.view as? HorizontalTabsComponent.View else {
            XCTFail("Expected HorizontalTabsComponent.View (after update)")
            return
        }
        
        elements = Self.collectAccessibilityElements(in: tabsView2)
        XCTAssertEqual(elements.count, 2)
        
        let updatedAllElement = elements.first(where: { $0.accessibilityLabel == "All" })
        XCTAssertFalse(updatedAllElement?.accessibilityTraits.contains(.selected) ?? true)
        
        let updatedUnreadElement = elements.first(where: { $0.accessibilityLabel == "Unread" })
        XCTAssertTrue(updatedUnreadElement?.accessibilityTraits.contains(.selected) ?? false)
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

