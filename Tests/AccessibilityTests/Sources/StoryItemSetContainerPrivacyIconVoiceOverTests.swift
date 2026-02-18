import StoryContainerScreen
import TelegramPresentationData
import UIKit
import XCTest

final class StoryItemSetContainerPrivacyIconVoiceOverTests: XCTestCase {
    func testEditableResolvesPrivacyLabelValueAndHint() {
        let resolved = StoryItemSetContainerPrivacyIconVoiceOver.resolve(
            strings: defaultPresentationStrings,
            privacy: .closeFriends,
            isEditable: true,
            peerTitle: "Me"
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_Context_Privacy)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Story_Privacy_CategoryCloseFriends)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testNonEditableResolvesTooltipHint() {
        let resolved = StoryItemSetContainerPrivacyIconVoiceOver.resolve(
            strings: defaultPresentationStrings,
            privacy: .contacts,
            isEditable: false,
            peerTitle: "Alice"
        )
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Story_Context_Privacy)
        XCTAssertEqual(resolved.value, defaultPresentationStrings.Story_Privacy_CategoryContacts)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.Story_TooltipPrivacyContacts("Alice").string)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}
