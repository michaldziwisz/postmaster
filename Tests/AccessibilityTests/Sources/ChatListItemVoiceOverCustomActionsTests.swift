import ChatListUI
import TelegramPresentationData
import XCTest

final class ChatListItemVoiceOverCustomActionsTests: XCTestCase {
    func testNoCustomActionsWhenEditing() {
        let actions = ChatListItemVoiceOver.resolveCustomActions(
            strings: defaultPresentationStrings,
            hasStories: true,
            hasWebApp: true,
            isEditing: true
        )
        XCTAssertTrue(actions.isEmpty)
    }
    
    func testOpenStoriesAction() {
        let actions = ChatListItemVoiceOver.resolveCustomActions(
            strings: defaultPresentationStrings,
            hasStories: true,
            hasWebApp: false,
            isEditing: false
        )
        XCTAssertEqual(actions, [
            ChatListItemVoiceOver.CustomAction(
                kind: .openStories,
                name: defaultPresentationStrings.VoiceOver_ChatList_OpenStories
            )
        ])
    }
    
    func testOpenWebAppAction() {
        let actions = ChatListItemVoiceOver.resolveCustomActions(
            strings: defaultPresentationStrings,
            hasStories: false,
            hasWebApp: true,
            isEditing: false
        )
        XCTAssertEqual(actions, [
            ChatListItemVoiceOver.CustomAction(
                kind: .openWebApp,
                name: defaultPresentationStrings.ChatList_InlineButtonOpenApp
            )
        ])
    }
    
    func testStableOrderWhenBothPresent() {
        let actions = ChatListItemVoiceOver.resolveCustomActions(
            strings: defaultPresentationStrings,
            hasStories: true,
            hasWebApp: true,
            isEditing: false
        )
        XCTAssertEqual(actions, [
            ChatListItemVoiceOver.CustomAction(
                kind: .openStories,
                name: defaultPresentationStrings.VoiceOver_ChatList_OpenStories
            ),
            ChatListItemVoiceOver.CustomAction(
                kind: .openWebApp,
                name: defaultPresentationStrings.ChatList_InlineButtonOpenApp
            )
        ])
    }
}

