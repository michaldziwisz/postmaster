import Display
import ShareController
import TelegramPresentationData
import UIKit
import XCTest

final class ShareInputFieldNodeVoiceOverTests: XCTestCase {
    func testTextViewUsesPlaceholderAsAccessibilityLabel() {
        XCTAssertTrue(Thread.isMainThread)
        
        let theme = ShareInputFieldNodeTheme(presentationTheme: defaultPresentationData().theme)
        let placeholder = "Details"
        let node = ShareInputFieldNode(theme: theme, strings: defaultPresentationStrings, placeholder: placeholder)
        
        _ = node.view
        _ = node.updateLayout(width: 320.0, inputCopyText: nil, transition: .immediate)
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        guard let textView = elements.compactMap({ $0 as? UITextView }).first else {
            XCTFail("Expected an accessible UITextView")
            return
        }
        
        XCTAssertEqual(textView.accessibilityLabel, placeholder)
    }
    
    func testClearButtonIsAccessibleWhenVisible() {
        XCTAssertTrue(Thread.isMainThread)
        
        let theme = ShareInputFieldNodeTheme(presentationTheme: defaultPresentationData().theme)
        let node = ShareInputFieldNode(theme: theme, strings: defaultPresentationStrings, placeholder: "Details")
        
        _ = node.view
        node.text = "Hello"
        _ = node.updateLayout(width: 320.0, inputCopyText: nil, transition: .immediate)
        
        let elements = Self.collectAccessibilityElements(in: node.view)
        let clearButtonLabel = defaultPresentationStrings.VoiceOver_Editing_ClearText
        
        guard let clearButton = elements.first(where: { $0.accessibilityLabel == clearButtonLabel }) else {
            XCTFail("Expected a clear button accessibility element with label: \(clearButtonLabel)")
            return
        }
        
        XCTAssertTrue(clearButton.accessibilityTraits.contains(.button))
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

