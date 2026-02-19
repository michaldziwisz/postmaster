import CameraScreen
import TelegramPresentationData
import XCTest

final class CameraModeControlVoiceOverTests: XCTestCase {
    func testResolveUsesCameraModeLabelAndHint() {
        let modeTitle = defaultPresentationStrings.Story_Camera_Photo
        let resolved = CameraModeControlVoiceOver.resolve(strings: defaultPresentationStrings, modeTitle: modeTitle)
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Camera_Mode)
        XCTAssertEqual(resolved.value, modeTitle)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Camera_ModeHint)
    }
}

