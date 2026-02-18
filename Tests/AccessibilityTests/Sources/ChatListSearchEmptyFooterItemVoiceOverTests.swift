import ChatListUI
import TelegramPresentationData
import XCTest

final class ChatListSearchEmptyFooterItemVoiceOverTests: XCTestCase {
    func testResolveNoQueryNoButton() {
        let resolved = ChatListSearchEmptyFooterItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            searchQuery: nil,
            showsSearchAllMessagesButton: false
        )
        
        XCTAssertEqual(
            resolved,
            ChatListSearchEmptyFooterItemVoiceOver.Resolved(
                label: "\(defaultPresentationStrings.ChatList_Search_NoResults)\n\(defaultPresentationStrings.ChatList_Search_NoResults)",
                searchAllMessagesButtonLabel: nil
            )
        )
    }
    
    func testResolveQueryWithButton() {
        let query = "telegram"
        let resolved = ChatListSearchEmptyFooterItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            searchQuery: query,
            showsSearchAllMessagesButton: true
        )
        
        XCTAssertEqual(
            resolved.label,
            "\(defaultPresentationStrings.ChatList_Search_NoResults)\n\(defaultPresentationStrings.ChatList_Search_NoResultsQueryDescription(query).string)"
        )
        XCTAssertEqual(resolved.searchAllMessagesButtonLabel, defaultPresentationStrings.ChatList_EmptyResult_SearchInAll)
    }
}

