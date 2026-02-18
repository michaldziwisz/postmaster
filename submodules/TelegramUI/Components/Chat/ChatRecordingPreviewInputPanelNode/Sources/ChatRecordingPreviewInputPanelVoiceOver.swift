import TelegramPresentationData
import UIKit

public enum ChatRecordingPreviewPlayButtonVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, isPlaying: Bool) -> Resolved {
        Resolved(
            label: isPlaying ? strings.VoiceOver_Media_PlaybackPause : strings.VoiceOver_Media_PlaybackPlay,
            hint: nil,
            traits: [.button, .startsMediaSession]
        )
    }
}

