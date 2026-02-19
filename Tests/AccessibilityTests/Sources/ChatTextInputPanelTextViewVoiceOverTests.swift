import ChatTextInputPanelNode
import XCTest

final class ChatTextInputPanelTextViewVoiceOverTests: XCTestCase {
    func testResolvePlaceholderWithoutStarLeavesText() {
        let resolved = ChatTextInputPanelTextViewVoiceOver.resolve(placeholder: "Message", placeholderHasStar: false)
        XCTAssertEqual(resolved.label, "Message")
        XCTAssertNil(resolved.hint)
    }
    
    func testResolvePlaceholderWithStarReplacesHashWithStarEmoji() {
        let resolved = ChatTextInputPanelTextViewVoiceOver.resolve(placeholder: "Pay # 123", placeholderHasStar: true)
        XCTAssertEqual(resolved.label, "Pay ⭐️ 123")
        XCTAssertNil(resolved.hint)
    }
}

