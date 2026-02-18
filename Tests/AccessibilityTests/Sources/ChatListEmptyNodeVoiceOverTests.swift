import ChatListUI
import XCTest

final class ChatListEmptyNodeVoiceOverTests: XCTestCase {
    func testResolveWithDescription() {
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "Title", description: "Description"), "Title\nDescription")
    }
    
    func testResolveWithoutDescription() {
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "Title", description: nil), "Title")
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "Title", description: ""), "Title")
    }
    
    func testResolveTrimsWhitespace() {
        XCTAssertEqual(ChatListEmptyNodeVoiceOver.resolve(title: "  Title  ", description: "  Description  "), "Title\nDescription")
    }
}

