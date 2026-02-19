import TelegramPresentationData
import UIKit

public enum ChatMessageBubbleItemNodeVoiceOver {
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
    
    public static func resolveAdCloseButton(strings: PresentationStrings) -> Resolved {
        return Resolved(label: strings.Common_Close, hint: nil, traits: [.button])
    }
    
    public static func resolveAuthorNameButton(strings: PresentationStrings, title: String, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: title,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}
