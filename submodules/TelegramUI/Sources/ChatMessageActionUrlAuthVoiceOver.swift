import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessageActionUrlAuthVoiceOver {
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
    
    public static func resolveAuthorizeToggle(strings: PresentationStrings, labelText: String, isOn: Bool, isEnabled: Bool) -> Resolved {
        resolveToggle(strings: strings, labelText: labelText, isOn: isOn, isEnabled: isEnabled)
    }
    
    public static func resolveAllowWriteToggle(strings: PresentationStrings, labelText: String, isOn: Bool, isEnabled: Bool) -> Resolved {
        resolveToggle(strings: strings, labelText: labelText, isOn: isOn, isEnabled: isEnabled)
    }
    
    private static func resolveToggle(strings: PresentationStrings, labelText: String, isOn: Bool, isEnabled: Bool) -> Resolved {
        let labelText = labelText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        if isOn {
            traits.insert(.selected)
        }
        
        return Resolved(
            label: labelText,
            value: isOn ? strings.VoiceOver_Common_On : strings.VoiceOver_Common_Off,
            hint: isEnabled ? strings.VoiceOver_Common_SwitchHint : nil,
            traits: traits
        )
    }
}

