import TelegramPresentationData
import TelegramUI
import XCTest

final class ChatHistoryNavigationButtonsVoiceOverTests: XCTestCase {
    func testDownWithoutUnreadHasScrollDownLabel() {
        let resolved = ChatHistoryNavigationButtonsVoiceOver.resolveDown(strings: defaultPresentationStrings, unreadCount: 0)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.KeyCommand_ScrollDown)
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
    }
    
    func testDownWithUnreadAddsUnreadValue() {
        let resolved = ChatHistoryNavigationButtonsVoiceOver.resolveDown(strings: defaultPresentationStrings, unreadCount: 3)
        
        XCTAssertEqual(resolved.value, defaultPresentationStrings.VoiceOver_Chat_UnreadMessages(3))
    }
    
    func testUpHasScrollUpLabel() {
        let resolved = ChatHistoryNavigationButtonsVoiceOver.resolveUp(strings: defaultPresentationStrings)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.KeyCommand_ScrollUp)
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
    }
    
    func testMentionsUsesMentionLabelAndGoToMessageHint() {
        let resolved = ChatHistoryNavigationButtonsVoiceOver.resolveMentions(strings: defaultPresentationStrings, mentionCount: 2)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_ContextMenuMention)
        XCTAssertEqual(resolved.value, "2")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_GoToOriginalMessage)
    }
    
    func testReactionsUsesReactionsLabelAndGoToMessageHint() {
        let resolved = ChatHistoryNavigationButtonsVoiceOver.resolveReactions(strings: defaultPresentationStrings, reactionsCount: 2)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.PeerInfo_Reactions)
        XCTAssertEqual(resolved.value, "2")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_GoToOriginalMessage)
    }
}

