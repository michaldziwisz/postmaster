import TelegramPresentationData
import UIKit

public enum ItemListToggleVoiceOver {
    public struct Resolved: Equatable {
        public let value: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(value: String, hint: String?, traits: UIAccessibilityTraits) {
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, isOn: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        if isOn {
            traits.insert(.selected)
        }
        
        return Resolved(
            value: isOn ? strings.VoiceOver_Common_On : strings.VoiceOver_Common_Off,
            hint: isEnabled ? strings.VoiceOver_Common_SwitchHint : nil,
            traits: traits
        )
    }
}

