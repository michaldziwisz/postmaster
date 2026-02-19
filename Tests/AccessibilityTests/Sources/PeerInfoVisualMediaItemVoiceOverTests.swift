import PeerInfoScreen
import TelegramPresentationData
import UIKit
import XCTest

final class PeerInfoVisualMediaItemVoiceOverTests: XCTestCase {
    func testResolvePhotoUsesPhotoLabelAndOpenHint() {
        let resolved = PeerInfoVisualMediaItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            kind: .photo,
            isSelectionMode: false,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Photo)
        XCTAssertNil(resolved.value)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.selected))
    }
    
    func testResolveGifUsesGifLabelFromMessageAnimationKey() {
        let resolved = PeerInfoVisualMediaItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            kind: .gif,
            isSelectionMode: false,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Message_Animation)
        XCTAssertNil(resolved.value)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveVideoIncludesDurationAsValue() {
        let resolved = PeerInfoVisualMediaItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            kind: .video(duration: "0:10"),
            isSelectionMode: false,
            isSelected: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_Video)
        XCTAssertEqual(resolved.value, "0:10")
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_OpenHint)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
    
    func testResolveSelectionModeUsesSelectedTraitAndNoHint() {
        let resolved = PeerInfoVisualMediaItemVoiceOver.resolve(
            strings: defaultPresentationStrings,
            kind: .photo,
            isSelectionMode: true,
            isSelected: true
        )
        
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
    }
}

