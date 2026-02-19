import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoScreenMemberItemVoiceOverTests: XCTestCase {
    func testResolveEnabledMemberIsButtonWithOpenHint() {
        let resolved = PeerInfoScreenMemberItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            value: defaultPresentationStrings.GroupInfo_LabelAdmin,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.value, defaultPresentationStrings.GroupInfo_LabelAdmin)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveDisabledMemberIsStaticText() {
        let resolved = PeerInfoScreenMemberItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            title: "Alice",
            value: nil,
            isEnabled: false
        )
        
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
    }
}
