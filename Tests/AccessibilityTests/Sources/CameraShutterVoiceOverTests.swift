import CameraScreen
import TelegramPresentationData
import XCTest

final class CameraShutterVoiceOverTests: XCTestCase {
    func testTakePhotoUsesCommonTakePhotoLabel() {
        let resolved = CameraShutterVoiceOver.resolve(strings: defaultPresentationStrings, state: .takePhoto)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Common_TakePhoto)
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
    }
    
    func testStartVideoRecordingUsesVoiceOverLabel() {
        let resolved = CameraShutterVoiceOver.resolve(strings: defaultPresentationStrings, state: .startVideoRecording)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Camera_StartVideoRecording)
    }
    
    func testStopVideoRecordingUsesVoiceOverLabel() {
        let resolved = CameraShutterVoiceOver.resolve(strings: defaultPresentationStrings, state: .stopVideoRecording)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Camera_StopVideoRecording)
    }
    
    func testStartLiveStreamUsesCameraLiveStreamLabel() {
        let resolved = CameraShutterVoiceOver.resolve(strings: defaultPresentationStrings, state: .startLiveStream)
        XCTAssertEqual(resolved.label, defaultPresentationStrings.Camera_LiveStream_StartLiveStream)
    }
}

