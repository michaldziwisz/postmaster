import PeerInfoAvatarListNode
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoAvatarListContainerVoiceOverTests: XCTestCase {
    func testEmptyListIsImageWithoutValueOrAdjustableTrait() {
        let resolved = PeerInfoAvatarListContainerVoiceOver.resolve(strings: defaultPresentationStrings, index: 0, count: 0)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Photo)
        XCTAssertNil(resolved.value)
        XCTAssertTrue(resolved.traits.contains(.image))
        XCTAssertFalse(resolved.traits.contains(.adjustable))
    }

    func testSingleItemIsImageWithValueWithoutAdjustableTrait() {
        let resolved = PeerInfoAvatarListContainerVoiceOver.resolve(strings: defaultPresentationStrings, index: 0, count: 1)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Photo)
        XCTAssertEqual(resolved.value, "1 of 1")
        XCTAssertTrue(resolved.traits.contains(.image))
        XCTAssertFalse(resolved.traits.contains(.adjustable))
    }

    func testMultipleItemsIsAdjustableWithClampedValue() {
        let resolved = PeerInfoAvatarListContainerVoiceOver.resolve(strings: defaultPresentationStrings, index: 1, count: 3)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Photo)
        XCTAssertEqual(resolved.value, "2 of 3")
        XCTAssertTrue(resolved.traits.contains(.image))
        XCTAssertTrue(resolved.traits.contains(.adjustable))
    }
}

