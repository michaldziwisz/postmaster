import CallListUI
import ObjectiveC.runtime
import XCTest

final class CallListCustomActionSignatureTests: XCTestCase {
    func testCallListItemCustomActionHandlerReturnsNonVoid() {
        let selector = NSSelectorFromString("performLocalAccessibilityCustomAction:")
        guard let targetClass = NSClassFromString("CallListUI.CallListCallItemNode") else {
            XCTFail("Expected CallListUI.CallListCallItemNode to exist")
            return
        }
        guard let method = class_getInstanceMethod(targetClass, selector) else {
            XCTFail("Expected CallListCallItemNode.performLocalAccessibilityCustomAction(_:) to exist")
            return
        }
        guard let typeEncoding = method_getTypeEncoding(method) else {
            XCTFail("Expected type encoding for CallListCallItemNode.performLocalAccessibilityCustomAction(_:) method")
            return
        }
        let encoding = String(cString: typeEncoding)
        
        XCTAssertFalse(encoding.hasPrefix("v"), "Expected non-void return type for custom action handler, got encoding: \(encoding)")
    }
}

