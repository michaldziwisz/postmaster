import ActionPanelComponent
import ComponentFlow
import TelegramPresentationData
import UIKit
import XCTest

final class ActionPanelComponentAccessibilityTests: XCTestCase {
    func testActionAndDismissButtonsAreAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivate = false
        var didDismiss = false
        
        let component = ActionPanelComponent(
            theme: defaultPresentationTheme,
            title: "New chats available",
            color: .accent,
            action: { didActivate = true },
            dismissAction: { didDismiss = true },
            dismissAccessibilityLabel: "Close"
        )
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {},
            containerSize: CGSize(width: 320.0, height: 44.0)
        )
        
        guard let panelView = componentView.view as? ActionPanelComponent.View else {
            XCTFail("Expected ActionPanelComponent.View")
            return
        }
        
        let accessibilityElements = Self.collectAccessibilityElements(in: panelView)
        XCTAssertEqual(accessibilityElements.count, 2)
        
        let actionButton = accessibilityElements.first(where: { $0.accessibilityLabel == "New chats available" })
        XCTAssertNotNil(actionButton)
        XCTAssertTrue(actionButton?.accessibilityTraits.contains(.button) ?? false)
        
        let closeButton = accessibilityElements.first(where: { $0.accessibilityLabel == "Close" })
        XCTAssertNotNil(closeButton)
        XCTAssertTrue(closeButton?.accessibilityTraits.contains(.button) ?? false)
        
        XCTAssertTrue(actionButton?.accessibilityActivate() ?? false)
        XCTAssertTrue(didActivate)
        XCTAssertFalse(didDismiss)
        
        XCTAssertTrue(closeButton?.accessibilityActivate() ?? false)
        XCTAssertTrue(didDismiss)
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

