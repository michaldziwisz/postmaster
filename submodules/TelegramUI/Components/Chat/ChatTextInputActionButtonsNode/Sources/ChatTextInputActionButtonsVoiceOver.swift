import Foundation
import TelegramPresentationData

public enum ChatTextInputActionButtonsVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        
        public init(label: String, hint: String?) {
            self.label = label
            self.hint = hint
        }
    }
    
    public static func resolve(strings: PresentationStrings, isMicVisible: Bool, isVideoMode: Bool) -> Resolved {
        if isMicVisible {
            if isVideoMode {
                return Resolved(label: strings.VoiceOver_Chat_RecordModeVideoMessage, hint: strings.VoiceOver_Chat_RecordModeVideoMessageInfo)
            } else {
                return Resolved(label: strings.VoiceOver_Chat_RecordModeVoiceMessage, hint: strings.VoiceOver_Chat_RecordModeVoiceMessageInfo)
            }
        } else {
            return Resolved(label: strings.MediaPicker_Send, hint: nil)
        }
    }
    
    public static func resolveExpandButton(strings: PresentationStrings, isExpanded: Bool) -> Resolved {
        if isExpanded {
            return Resolved(label: strings.VoiceOver_Chat_CollapseInput, hint: nil)
        } else {
            return Resolved(label: strings.VoiceOver_Chat_ExpandInput, hint: nil)
        }
    }
}
