import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatManagingBotTitlePanelVoiceOverTests: XCTestCase {
    func testResolveTitleIsHeader() {
        let resolved = ChatManagingBotTitlePanelVoiceOver.resolveTitle("  Bot Name  ")
        
        XCTAssertEqual(resolved.label, "Bot Name")
        XCTAssertTrue(resolved.traits.contains(.header))
    }
    
    func testResolveStatusIsStaticText() {
        let resolved = ChatManagingBotTitlePanelVoiceOver.resolveStatus("  bot paused  ")
        
        XCTAssertEqual(resolved.label, "bot paused")
        XCTAssertTrue(resolved.traits.contains(.staticText))
    }
    
    func testResolveActionButtonStartWhenPaused() {
        let resolved = ChatManagingBotTitlePanelVoiceOver.resolveActionButton(
            strings: defaultPresentationStrings,
            isPaused: true,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_BusinessBotPanel_ActionStart)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveActionButtonStopWhenRunning() {
        let resolved = ChatManagingBotTitlePanelVoiceOver.resolveActionButton(
            strings: defaultPresentationStrings,
            isPaused: false,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Chat_BusinessBotPanel_ActionStop)
    }
    
    func testResolveSettingsButtonUsesMoreLabel() {
        let resolved = ChatManagingBotTitlePanelVoiceOver.resolveSettingsButton(strings: defaultPresentationStrings, isEnabled: true)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_More)
    }
    
    func testDisabledAddsNotEnabledTrait() {
        let resolved = ChatManagingBotTitlePanelVoiceOver.resolveSettingsButton(strings: defaultPresentationStrings, isEnabled: false)
        
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

