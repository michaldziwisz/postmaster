import TelegramPresentationData
import UIKit

public enum GiftOptionItemVoiceOver {
    public struct Resolved: Equatable {
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(hint: String?, traits: UIAccessibilityTraits) {
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, isEnabled: Bool, isSelected: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}

