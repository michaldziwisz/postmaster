import Foundation
import TelegramPresentationData
import UIKit

public enum ChatPremiumRequiredInputPanelVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String, subtitle: String?, isEnabled: Bool) -> Resolved {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let subtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: title,
            value: (subtitle?.isEmpty ?? true) ? nil : subtitle,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}

