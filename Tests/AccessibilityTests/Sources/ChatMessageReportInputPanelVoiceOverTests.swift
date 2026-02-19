import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class ChatMessageReportInputPanelVoiceOverTests: XCTestCase {
    func testResolveReportButtonAddsNotEnabledTraitWhenDisabled() {
        let resolved = ChatMessageReportInputPanelVoiceOver.resolveReportButton(
            strings: defaultPresentationStrings,
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Conversation_ReportMessages)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.notEnabled))
    }
}

