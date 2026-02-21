import ComponentFlow
import TabBarComponent
import TelegramPresentationData
import UIKit
import XCTest

final class TabBarComponentAccessibilityTests: XCTestCase {
    func testTabItemsAreAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivateChats = false
        
        let chatsItem = UITabBarItem(title: "Chats", image: nil, selectedImage: nil)
        chatsItem.badgeValue = "3"
        
        let settingsItem = UITabBarItem(title: "Settings", image: nil, selectedImage: nil)
        
        let items: [TabBarComponent.Item] = [
            TabBarComponent.Item(item: chatsItem, action: { _ in
                didActivateChats = true
            }, contextAction: nil),
            TabBarComponent.Item(item: settingsItem, action: { _ in
            }, contextAction: nil),
        ]
        
        let component = TabBarComponent(
            theme: defaultPresentationTheme,
            strings: defaultPresentationStrings,
            items: items,
            search: nil,
            selectedId: AnyHashable(ObjectIdentifier(chatsItem)),
            outerInsets: .zero
        )
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {},
            containerSize: CGSize(width: 320.0, height: 72.0)
        )
        
        guard let tabBarView = componentView.view as? TabBarComponent.View else {
            XCTFail("Expected TabBarComponent.View")
            return
        }
        
        let accessibilityElements = tabBarView.accessibilityElements as? [UIAccessibilityElement] ?? []
        let chatsElements = accessibilityElements.filter { $0.accessibilityLabel == "Chats" }
        XCTAssertEqual(chatsElements.count, 1)
        
        let chatsElement = chatsElements[0]
        XCTAssertTrue(chatsElement.accessibilityTraits.contains(.button))
        XCTAssertTrue(chatsElement.accessibilityTraits.contains(.selected))
        XCTAssertEqual(chatsElement.accessibilityValue, "3")
        
        XCTAssertTrue(chatsElement.accessibilityActivate())
        XCTAssertTrue(didActivateChats)
        
        let settingsElements = accessibilityElements.filter { $0.accessibilityLabel == "Settings" }
        XCTAssertEqual(settingsElements.count, 1)
        XCTAssertTrue(settingsElements[0].accessibilityTraits.contains(.button))
    }

    func testNavigationSearchViewIsAccessibleWhenInactive() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivate = false
        var didClose = false
        
        let searchView = NavigationSearchView(
            action: { didActivate = true },
            closeAction: { didClose = true }
        )
        
        searchView.update(
            size: CGSize(width: 200.0, height: 48.0),
            theme: defaultPresentationTheme,
            strings: defaultPresentationStrings,
            isActive: false,
            transition: .immediate
        )
        
        XCTAssertTrue(searchView.isAccessibilityElement)
        XCTAssertTrue(searchView.accessibilityTraits.contains(.button))
        XCTAssertEqual(searchView.accessibilityLabel, defaultPresentationStrings.Common_Search)
        XCTAssertTrue(searchView.accessibilityActivate())
        XCTAssertTrue(didActivate)
        XCTAssertFalse(didClose)
    }
    
    func testNavigationSearchViewExposesCloseButtonWhenActive() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didClose = false
        
        let searchView = NavigationSearchView(
            action: {},
            closeAction: { didClose = true }
        )
        
        searchView.update(
            size: CGSize(width: 200.0, height: 48.0),
            theme: defaultPresentationTheme,
            strings: defaultPresentationStrings,
            isActive: true,
            transition: .immediate
        )
        
        XCTAssertFalse(searchView.isAccessibilityElement)
        
        let elements = Self.collectAccessibilityElements(in: searchView)
        XCTAssertTrue(elements.contains(where: { view in
            view.accessibilityLabel == defaultPresentationStrings.Common_Close && view.accessibilityTraits.contains(.button)
        }))
        
        let closeButton = elements.first(where: { $0.accessibilityLabel == defaultPresentationStrings.Common_Close })
        XCTAssertTrue(closeButton?.accessibilityActivate() ?? false)
        XCTAssertTrue(didClose)
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
