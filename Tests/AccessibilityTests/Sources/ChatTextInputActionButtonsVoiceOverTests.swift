import ChatTextInputActionButtonsNode
import TelegramPresentationData
import XCTest

final class ChatTextInputActionButtonsVoiceOverTests: XCTestCase {
    func testResolveSendButtonLabelAndHint() {
        let resolved = ChatTextInputActionButtonsVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isMicVisible: false,
            isVideoMode: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.MediaPicker_Send)
        XCTAssertNil(resolved.hint)
    }
    
    func testResolveMicAudioLabelAndHint() {
        let resolved = ChatTextInputActionButtonsVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isMicVisible: true,
            isVideoMode: false
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_RecordModeVoiceMessage)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_RecordModeVoiceMessageInfo)
    }
    
    func testResolveMicVideoLabelAndHint() {
        let resolved = ChatTextInputActionButtonsVoiceOver.resolve(
            strings: defaultPresentationStrings,
            isMicVisible: true,
            isVideoMode: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.VoiceOver_Chat_RecordModeVideoMessage)
        XCTAssertEqual(resolved.hint, defaultPresentationStrings.VoiceOver_Chat_RecordModeVideoMessageInfo)
    }
}

