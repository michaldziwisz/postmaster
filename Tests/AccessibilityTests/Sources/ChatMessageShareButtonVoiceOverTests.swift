import ChatMessageShareButton
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessageShareButtonVoiceOverTests: XCTestCase {
    func testResolveShareUsesShareLabel() {
        let resolved = ChatMessageShareButtonVoiceOver.resolve(strings: defaultPresentationStrings, mode: .share)
        
        XCTAssertEqual(resolved.top.label, defaultPresentationStrings.VoiceOver_MessageContextShare)
        XCTAssertNil(resolved.bottom)
        XCTAssertTrue(resolved.top.traits.contains(.button))
    }
    
    func testResolveNavigateUsesGoToMessageLabel() {
        let resolved = ChatMessageShareButtonVoiceOver.resolve(strings: defaultPresentationStrings, mode: .navigate)
        XCTAssertEqual(resolved.top.label, defaultPresentationStrings.VoiceOver_Chat_GoToOriginalMessage)
    }
    
    func testResolveAdHasMoreAddsBottomMoreButton() {
        let resolved = ChatMessageShareButtonVoiceOver.resolve(strings: defaultPresentationStrings, mode: .ad(hasMore: true))
        
        XCTAssertEqual(resolved.top.label, defaultPresentationStrings.Common_Close)
        XCTAssertEqual(resolved.bottom?.label, defaultPresentationStrings.Common_More)
    }
    
    func testResolveCommentsIncludesCountAndSpace() {
        let resolved = ChatMessageShareButtonVoiceOver.resolve(strings: defaultPresentationStrings, mode: .comments(count: 5))
        
        XCTAssertEqual(resolved.top.label, "5 Comments")
        XCTAssertTrue(resolved.top.label.contains("5 "))
    }
    
    func testResolveSummaryExpandedAddsSelectedTrait() {
        let resolved = ChatMessageShareButtonVoiceOver.resolve(strings: defaultPresentationStrings, mode: .summary(isExpanded: true))
        
        XCTAssertEqual(resolved.top.label, defaultPresentationStrings.Conversation_Summary_Title)
        XCTAssertTrue(resolved.top.traits.contains(.selected))
        if #available(iOS 17.0, *) {
            XCTAssertTrue(resolved.top.traits.contains(.toggleButton))
        }
    }
}

