import TelegramPresentationData
import UIKit

public enum VideoChatMicButtonComponentVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, content: VideoChatMicButtonComponent.Content, isCompact: Bool) -> Resolved {
        var label: String
        var hint: String?
        var traits: UIAccessibilityTraits = [.button]
        
        switch content {
        case .connecting:
            label = strings.VoiceChat_Connecting
            traits.insert(.notEnabled)
            traits.insert(.startsMediaSession)
        case let .muted(forced):
            if forced {
                label = strings.VoiceChat_MutedByAdmin
            } else {
                label = strings.VoiceChat_Unmute
            }
            traits.insert(.startsMediaSession)
        case let .unmuted(isPushToTalk):
            label = isPushToTalk ? strings.VoiceChat_Live : strings.VoiceChat_MuteShort
            traits.insert(.startsMediaSession)
        case let .raiseHand(isRaised):
            if isRaised {
                label = strings.VoiceChat_AskedToSpeak
                hint = strings.VoiceChat_AskedToSpeakHelp
            } else {
                label = strings.VoiceChat_MutedByAdmin
                hint = strings.VoiceChat_MutedByAdminHelp
            }
        case let .scheduled(state):
            switch state {
            case .start:
                label = strings.VoiceChat_StartNow
            case let .toggleSubscription(isSubscribed):
                label = isSubscribed ? strings.VoiceChat_CancelReminder : strings.VoiceChat_SetReminder
            }
        }
        
        if isCompact {
            label = label.lowercased()
        }
        
        return Resolved(label: label, hint: hint, traits: traits)
    }
}

