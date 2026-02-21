import ChatMessageAnimatedStickerItemNode
import ChatMessageBubbleItemNode
import ChatMessageInstantVideoItemNode
import ChatMessageStickerItemNode
import ObjectiveC.runtime
import XCTest

final class ChatMessageCustomActionSignatureTests: XCTestCase {
    func testBubbleItemCustomActionHandlerReturnsNonVoid() {
        assertCustomActionHandlerReturnsNonVoid(ChatMessageBubbleItemNode.self)
    }
    
    func testAnimatedStickerItemCustomActionHandlerReturnsNonVoid() {
        assertCustomActionHandlerReturnsNonVoid(ChatMessageAnimatedStickerItemNode.self)
    }
    
    func testInstantVideoItemCustomActionHandlerReturnsNonVoid() {
        assertCustomActionHandlerReturnsNonVoid(ChatMessageInstantVideoItemNode.self)
    }
    
    func testStickerItemCustomActionHandlerReturnsNonVoid() {
        assertCustomActionHandlerReturnsNonVoid(ChatMessageStickerItemNode.self)
    }
}

private func assertCustomActionHandlerReturnsNonVoid(_ targetClass: AnyClass, file: StaticString = #filePath, line: UInt = #line) {
    let selector = NSSelectorFromString("performLocalAccessibilityCustomAction:")
    guard let method = class_getInstanceMethod(targetClass, selector) else {
        XCTFail("Expected \(targetClass).performLocalAccessibilityCustomAction(_:) to exist", file: file, line: line)
        return
    }
    guard let typeEncoding = method_getTypeEncoding(method) else {
        XCTFail("Expected type encoding for \(targetClass).performLocalAccessibilityCustomAction(_:) method", file: file, line: line)
        return
    }
    let encoding = String(cString: typeEncoding)
    
    XCTAssertFalse(encoding.hasPrefix("v"), "Expected non-void return type for custom action handler, got encoding: \(encoding)", file: file, line: line)
}
