import Foundation
import TelegramPresentationData

public enum CameraModeControlVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String
        public let hint: String?
        
        public init(label: String, value: String, hint: String? = nil) {
            self.label = label
            self.value = value
            self.hint = hint
        }
    }
    
    public static func resolve(strings: PresentationStrings, modeTitle: String) -> Resolved {
        return Resolved(
            label: strings.VoiceOver_Camera_Mode,
            value: modeTitle,
            hint: strings.VoiceOver_Camera_ModeHint
        )
    }
}

