import CameraButtonComponent
import ComponentFlow
import UIKit
import XCTest

final class CameraButtonComponentAccessibilityTests: XCTestCase {
    func testButtonIsAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivate = false
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(CameraButton(
                content: AnyComponentWithIdentity(id: "content", component: AnyComponent(TestContentComponent())),
                action: {
                    didActivate = true
                },
                accessibilityLabel: "Switch camera"
            )),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? CameraButton.View else {
            XCTFail("Expected CameraButton.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 1)
        
        let buttonElement = elements[0]
        XCTAssertEqual(buttonElement.accessibilityLabel, "Switch camera")
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
            component: AnyComponent(CameraButton(
                content: AnyComponentWithIdentity(id: "content", component: AnyComponent(TestContentComponent())),
                isEnabled: false,
                action: {},
                accessibilityLabel: "Flash"
            )),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? CameraButton.View else {
            XCTFail("Expected CameraButton.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 1)
        
        let buttonElement = elements[0]
        XCTAssertEqual(buttonElement.accessibilityLabel, "Flash")
        XCTAssertTrue(buttonElement.accessibilityTraits.contains(.button))
        XCTAssertTrue(buttonElement.accessibilityTraits.contains(.notEnabled))
    }
    
    func testButtonIsNotAccessibleWhenNotVisible() {
        XCTAssertTrue(Thread.isMainThread)
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(CameraButton(
                content: AnyComponentWithIdentity(id: "content", component: AnyComponent(TestContentComponent())),
                action: {},
                accessibilityLabel: "Hidden",
                isVisible: false
            )),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? CameraButton.View else {
            XCTFail("Expected CameraButton.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 0)
    }
    
    func testButtonSupportsAccessibilityCustomActionForLongPress() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didLongPress = false
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(CameraButton(
                content: AnyComponentWithIdentity(id: "content", component: AnyComponent(TestContentComponent())),
                action: {},
                longTapAction: {
                    didLongPress = true
                },
                accessibilityLabel: "Flash",
                accessibilityLongPressActionName: "Flash tint"
            )),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? CameraButton.View else {
            XCTFail("Expected CameraButton.View")
            return
        }
        
        let actions = buttonView.accessibilityCustomActions ?? []
        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].name, "Flash tint")
        XCTAssertTrue(actions[0].actionHandler?(actions[0]) ?? false)
        XCTAssertTrue(didLongPress)
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
