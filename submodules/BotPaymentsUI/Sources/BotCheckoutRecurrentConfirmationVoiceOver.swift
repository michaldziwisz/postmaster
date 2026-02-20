import TelegramPresentationData
import UIKit

public enum BotCheckoutRecurrentConfirmationVoiceOver {
    public struct ToggleResolved: Equatable {
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
    
    public struct LinkResolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolveToggle(strings: PresentationStrings, label: String, isSelected: Bool, isEnabled: Bool) -> ToggleResolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return ToggleResolved(
            label: label,
            value: isSelected ? strings.VoiceOver_Common_On : strings.VoiceOver_Common_Off,
            hint: isEnabled ? strings.VoiceOver_Common_SwitchHint : nil,
            traits: traits
        )
    }
    
    public static func resolveLink(strings: PresentationStrings, label: String, isEnabled: Bool) -> LinkResolved {
        var traits: UIAccessibilityTraits = [.staticText]
        if isEnabled {
            traits.insert(.link)
        }
        return LinkResolved(
            label: label,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits
        )
    }
}

