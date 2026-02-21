import Display
import NavigationBarImpl
import TelegramPresentationData
import UIKit
import XCTest

final class NavigationBarImplAccessibilityTests: XCTestCase {
    func testBackButtonIsAccessibleWhenBackTitleIsHidden() {
        XCTAssertTrue(Thread.isMainThread)
        
        var didBack = false
        
        let presentationData = NavigationBarPresentationData(
            presentationTheme: defaultPresentationTheme,
            presentationStrings: defaultPresentationStrings,
            style: .glass
        )
        
        let navigationBar = NavigationBarImpl(presentationData: presentationData)
        navigationBar.backPressed = {
            didBack = true
        }
        
        let previousItem = UINavigationItem(title: "Chats")
        let currentItem = UINavigationItem(title: "Chat")
        
        navigationBar.previousItem = .item(previousItem)
        navigationBar.item = currentItem
        
        let accessibilityElements = navigationBar.accessibilityElements as? [Any] ?? []
        let backElement = accessibilityElements.compactMap { $0 as? UIAccessibilityElement }.first(where: { element in
            element.accessibilityTraits.contains(.button) && element.accessibilityLabel == defaultPresentationStrings.Common_Back
        })
        
        XCTAssertNotNil(backElement)
        
        XCTAssertTrue(backElement?.accessibilityActivate() ?? false)
        XCTAssertTrue(didBack)
    }
}

