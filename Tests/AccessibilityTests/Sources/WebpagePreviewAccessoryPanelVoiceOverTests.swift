import TelegramPresentationData
import TelegramUI
import UIKit
import XCTest

final class WebpagePreviewAccessoryPanelVoiceOverTests: XCTestCase {
    func testResolveUsesTitleLabelAndTextValue() {
        let resolved = WebpagePreviewAccessoryPanelVoiceOver.resolve(strings: defaultPresentationStrings, title: "Example", text: "Video")
        
        XCTAssertEqual(resolved.label, "Example")
        XCTAssertEqual(resolved.value, "Video")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        
        XCTAssertEqual(resolved.customActions.count, 1)
        XCTAssertEqual(resolved.customActions[0].kind, .close)
        XCTAssertEqual(resolved.customActions[0].name, defaultPresentationStrings.VoiceOver_DiscardPreparedContent)
    }
    
    func testResolveOmitsEmptyTextValue() {
        let resolved = WebpagePreviewAccessoryPanelVoiceOver.resolve(strings: defaultPresentationStrings, title: "Example", text: "   ")
        XCTAssertNil(resolved.value)
    }
}

