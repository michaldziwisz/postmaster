import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatTagSearchInputPanelVoiceOverTests: XCTestCase {
    func testResolveCalendarButtonUsesCalendarTitleAndOpenHint() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveCalendarButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.MessageCalendar_Title)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveMembersButtonUsesSearchMembersLabel() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveMembersButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_SearchByName_Placeholder)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveResultsTextWhenDisabledUsesStaticTextTrait() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveResultsText(
            text: "3 of 10",
            isToggleEnabled: false,
            strings: defaultPresentationStrings
        )
        
        XCTAssertEqual(resolved.label, "3 of 10")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
    
    func testResolveResultsTextWhenEnabledUsesSwitchHintAndButtonTrait() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveResultsText(
            text: "12 messages",
            isToggleEnabled: true,
            strings: defaultPresentationStrings
        )
        
        XCTAssertEqual(resolved.label, "12 messages")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveListModeButtonLabelWhenDisplayingAsList() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveListModeButton(
            strings: defaultPresentationStrings,
            isDisplayingAsList: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_BottomSearchPanel_DisplayModeFormat(defaultPresentationStrings.Chat_BottomSearchPanel_DisplayModeChat).string)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Common_SwitchHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveListModeButtonLabelWhenDisplayingAsChat() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveListModeButton(
            strings: defaultPresentationStrings,
            isDisplayingAsList: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_BottomSearchPanel_DisplayModeFormat(defaultPresentationStrings.Chat_BottomSearchPanel_DisplayModeList).string)
    }
    
    func testResolveListModeButtonDisabledAddsNotEnabledTraitAndNoHint() {
        let resolved = ChatTagSearchInputPanelVoiceOver.resolveListModeButton(
            strings: defaultPresentationStrings,
            isDisplayingAsList: false,
            isEnabled: false
        )
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
        XCTAssertNil(resolved.hint)
    }
}

