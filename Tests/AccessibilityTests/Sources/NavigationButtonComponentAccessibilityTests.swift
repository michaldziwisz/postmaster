import ChatListHeaderComponent
import ComponentFlow
import TelegramPresentationData
import UIKit
import XCTest

final class NavigationButtonComponentAccessibilityTests: XCTestCase {
    func testTextButtonHasAccessibilityLabelAndActivates() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let component = NavigationButtonComponent(
            content: .text(title: "Edit", isBold: false),
            pressed: { _ in
                didPress = true
            }
        )
        
        let componentView = ComponentView<NavigationButtonComponentEnvironment>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {
                NavigationButtonComponentEnvironment(theme: defaultPresentationTheme)
            },
            containerSize: CGSize(width: 100.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? NavigationButtonComponent.View else {
            XCTFail("Expected NavigationButtonComponent.View")
            return
        }
        
        XCTAssertTrue(buttonView.isAccessibilityElement)
        XCTAssertTrue(buttonView.accessibilityTraits.contains(.button))
        XCTAssertEqual(buttonView.accessibilityLabel, "Edit")
        
        XCTAssertTrue(buttonView.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
    
    func testIconButtonUsesProvidedAccessibilityLabel() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let component = NavigationButtonComponent(
            content: .icon(imageName: "Chat List/ComposeIcon"),
            accessibilityLabel: "New Message",
            pressed: { _ in
                didPress = true
            }
        )
        
        let componentView = ComponentView<NavigationButtonComponentEnvironment>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {
                NavigationButtonComponentEnvironment(theme: defaultPresentationTheme)
            },
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? NavigationButtonComponent.View else {
            XCTFail("Expected NavigationButtonComponent.View")
            return
        }
        
        XCTAssertTrue(buttonView.isAccessibilityElement)
        XCTAssertEqual(buttonView.accessibilityLabel, "New Message")
        
        XCTAssertTrue(buttonView.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
    
    func testIconButtonDerivesAccessibilityLabelFromImageNameWhenNotProvided() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let component = NavigationButtonComponent(
            content: .icon(imageName: "Chat List/AddIcon"),
            pressed: { _ in
                didPress = true
            }
        )
        
        let componentView = ComponentView<NavigationButtonComponentEnvironment>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {
                NavigationButtonComponentEnvironment(theme: defaultPresentationTheme)
            },
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? NavigationButtonComponent.View else {
            XCTFail("Expected NavigationButtonComponent.View")
            return
        }
        
        XCTAssertTrue(buttonView.isAccessibilityElement)
        XCTAssertEqual(buttonView.accessibilityLabel, "Add")
        
        XCTAssertTrue(buttonView.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
    
    func testProxyButtonHasFallbackAccessibilityLabelWhenNotProvided() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let component = NavigationButtonComponent(
            content: .proxy(status: .available),
            pressed: { _ in
                didPress = true
            }
        )
        
        let componentView = ComponentView<NavigationButtonComponentEnvironment>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {
                NavigationButtonComponentEnvironment(theme: defaultPresentationTheme)
            },
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? NavigationButtonComponent.View else {
            XCTFail("Expected NavigationButtonComponent.View")
            return
        }
        
        XCTAssertTrue(buttonView.isAccessibilityElement)
        XCTAssertEqual(buttonView.accessibilityLabel, "Proxy")
        
        XCTAssertTrue(buttonView.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
    
    func testMoreButtonUsesProvidedAccessibilityLabel() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didPress = false
        let component = NavigationButtonComponent(
            content: .more,
            accessibilityLabel: defaultPresentationStrings.Common_More,
            pressed: { _ in
                didPress = true
            }
        )
        
        let componentView = ComponentView<NavigationButtonComponentEnvironment>()
        _ = componentView.update(
            transition: .immediate,
            component: AnyComponent(component),
            environment: {
                NavigationButtonComponentEnvironment(theme: defaultPresentationTheme)
            },
            containerSize: CGSize(width: 44.0, height: 44.0)
        )
        
        guard let buttonView = componentView.view as? NavigationButtonComponent.View else {
            XCTFail("Expected NavigationButtonComponent.View")
            return
        }
        
        XCTAssertTrue(buttonView.isAccessibilityElement)
        XCTAssertEqual(buttonView.accessibilityLabel, defaultPresentationStrings.Common_More)
        
        XCTAssertTrue(buttonView.accessibilityActivate())
        XCTAssertTrue(didPress)
    }
}
