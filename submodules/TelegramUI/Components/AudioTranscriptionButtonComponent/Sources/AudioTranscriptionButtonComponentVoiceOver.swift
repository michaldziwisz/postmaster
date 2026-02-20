import Foundation
import TelegramPresentationData
import UIKit

public enum AudioTranscriptionButtonComponentVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, state: AudioTranscriptionButtonComponent.TranscriptionState) -> Resolved {
        let label = strings.GroupBoost_AudioTranscription
        
        var value: String?
        let hint: String? = nil
        var traits: UIAccessibilityTraits = [.button]
        
        switch state {
        case .inProgress:
            traits.insert(.updatesFrequently)
            value = strings.Channel_NotificationLoading
        case .expanded:
            traits.insert(.selected)
            if #available(iOS 17.0, *) {
                traits.insert(.toggleButton)
            }
        case .collapsed:
            break
        case .locked:
            value = strings.Intents_ErrorLockedTitle
        }
        
        return Resolved(label: label, value: value, hint: hint, traits: traits)
    }
}
