import ChatListUI
import ObjectiveC.runtime
import XCTest

final class ChatListCustomActionSignatureTests: XCTestCase {
    func testChatListItemCustomActionHandlerReturnsNonVoid() {
        let selector = NSSelectorFromString("performLocalAccessibilityCustomAction:")
        guard let method = class_getInstanceMethod(ChatListItemNode.self, selector) else {
            XCTFail("Expected ChatListItemNode.performLocalAccessibilityCustomAction(_:) to exist")
            return
        }
        guard let typeEncoding = method_getTypeEncoding(method) else {
            XCTFail("Expected type encoding for ChatListItemNode.performLocalAccessibilityCustomAction(_:) method")
            return
        }
        let encoding = String(cString: typeEncoding)
        
        XCTAssertFalse(encoding.hasPrefix("v"), "Expected non-void return type for custom action handler, got encoding: \(encoding)")
    }
}

