import ComponentFlow
import GlassBarButtonComponent
import UIKit
import XCTest

final class GlassBarButtonComponentAccessibilityTests: XCTestCase {
    func testButtonIsAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivate = false
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(GlassBarButtonComponent(
                size: CGSize(width: 44.0, height: 44.0),
                backgroundColor: nil,
                isDark: false,
                state: .generic,
                isEnabled: true,
                isVisible: true,
                animateScale: false,
                component: AnyComponentWithIdentity(
                    id: "content",
                    component: AnyComponent(TestContentComponent())
                ),
                action: { _ in
                    didActivate = true
                },
                accessibilityLabel: "Close",
                accessibilityHint: nil
            )),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? GlassBarButtonComponent.View else {
            XCTFail("Expected GlassBarButtonComponent.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 1)
        
        let buttonElement = elements[0]
        XCTAssertEqual(buttonElement.accessibilityLabel, "Close")
        XCTAssertTrue(buttonElement.accessibilityTraits.contains(.button))
        XCTAssertFalse(buttonElement.accessibilityTraits.contains(.notEnabled))
        
        XCTAssertTrue(buttonElement.accessibilityActivate())
        XCTAssertTrue(didActivate)
    }
    
    func testButtonUsesNotEnabledTraitWhenDisabled() {
        XCTAssertTrue(Thread.isMainThread)
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(GlassBarButtonComponent(
                size: CGSize(width: 44.0, height: 44.0),
                backgroundColor: nil,
                isDark: false,
                state: .generic,
                isEnabled: false,
                isVisible: true,
                animateScale: false,
                component: AnyComponentWithIdentity(
                    id: "content",
                    component: AnyComponent(TestContentComponent())
                ),
                action: nil,
                accessibilityLabel: "Search",
                accessibilityHint: nil
            )),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? GlassBarButtonComponent.View else {
            XCTFail("Expected GlassBarButtonComponent.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 1)
        
        let buttonElement = elements[0]
        XCTAssertEqual(buttonElement.accessibilityLabel, "Search")
        XCTAssertTrue(buttonElement.accessibilityTraits.contains(.button))
        XCTAssertTrue(buttonElement.accessibilityTraits.contains(.notEnabled))
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

private struct TestContentComponent: Component {
    func makeView() -> UIView {
        UIView()
    }
    
    func update(view: UIView, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        return CGSize(width: 1.0, height: 1.0)
    }
}

