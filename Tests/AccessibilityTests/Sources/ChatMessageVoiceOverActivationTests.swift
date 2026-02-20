import ChatMessageItemView
import XCTest

final class ChatMessageVoiceOverActivationTests: XCTestCase {
    func testPerformNilReturnsFalse() {
        XCTAssertFalse(ChatMessageVoiceOverActivation.perform(nil))
    }
    
    func testPerformOptionalActionExecutesAndReturnsTrue() {
        var didExecute = false
        let action: InternalBubbleTapAction = .optionalAction({ didExecute = true })
        
        XCTAssertTrue(ChatMessageVoiceOverActivation.perform(action))
        XCTAssertTrue(didExecute)
    }
    
    func testPerformActionExecutesAndReturnsTrue() {
        var didExecute = false
        let action: InternalBubbleTapAction = .action(InternalBubbleTapAction.Action({ didExecute = true }))
        
        XCTAssertTrue(ChatMessageVoiceOverActivation.perform(action))
        XCTAssertTrue(didExecute)
    }
}

