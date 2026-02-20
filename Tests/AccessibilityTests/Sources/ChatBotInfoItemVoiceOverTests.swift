import ChatBotInfoItem
import TelegramPresentationData
import UIKit
import XCTest

final class ChatBotInfoItemVoiceOverTests: XCTestCase {
    func testResolveNoActionOmitsHintAndLinkTrait() {
        let resolved = ChatBotInfoItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Title",
            text: "Text",
            actionKind: nil
        )
        
        XCTAssertEqual(resolved.label, "Title. Text")
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.link))
    }
    
    func testResolveUrlAddsLinkTraitAndOpenLinkHint() {
        let resolved = ChatBotInfoItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Title",
            text: "Text",
            actionKind: .url
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenLinkHint)
        XCTAssertTrue(resolved.traits.contains(.link))
    }
    
    func testResolveOtherActionUsesOpenHint() {
        let resolved = ChatBotInfoItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Title",
            text: "Text",
            actionKind: .other
        )
        
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertFalse(resolved.traits.contains(.link))
    }
}

