import ComponentFlow
import UIKit
import XCTest

final class ButtonAccessibilityTests: XCTestCase {
    func testButtonIsAccessibleAndActivatable() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didActivate = false
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(
                Button(
                    content: AnyComponent(TestContentComponent()),
                    action: {
                        didActivate = true
                    }
                ).withAccessibility(label: "Take Photo")
            ),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? Button.View else {
            XCTFail("Expected Button.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 1)
        
        let element = elements[0]
        XCTAssertEqual(element.accessibilityLabel, "Take Photo")
        XCTAssertTrue(element.accessibilityTraits.contains(.button))
        XCTAssertFalse(element.accessibilityTraits.contains(.notEnabled))
        
        XCTAssertTrue(element.accessibilityActivate())
        XCTAssertTrue(didActivate)
    }
    
    func testButtonUsesNotEnabledTraitWhenDisabled() {
        XCTAssertTrue(Thread.isMainThread)
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(
                Button(
                    content: AnyComponent(TestContentComponent()),
                    isEnabled: false,
                    action: {}
                ).withAccessibility(label: "Shutter")
            ),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? Button.View else {
            XCTFail("Expected Button.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 1)
        
        let element = elements[0]
        XCTAssertEqual(element.accessibilityLabel, "Shutter")
        XCTAssertTrue(element.accessibilityTraits.contains(.button))
        XCTAssertTrue(element.accessibilityTraits.contains(.notEnabled))
    }
    
    func testButtonIsNotAccessibleWhenNotVisible() {
        XCTAssertTrue(Thread.isMainThread)
        
        let componentView = ComponentView<Empty>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(
                Button(
                    content: AnyComponent(TestContentComponent()),
                    action: {}
                ).withAccessibility(label: "Hidden", isVisible: false)
            ),
            environment: {},
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? Button.View else {
            XCTFail("Expected Button.View")
            return
        }
        
        let elements = Self.collectAccessibilityElements(in: buttonView)
        XCTAssertEqual(elements.count, 0)
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

