import TelegramPresentationData
import UIKit

public enum StarReactionButtonComponentVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, count: Int, isFilled: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isFilled {
            traits.insert(.selected)
            if #available(iOS 17.0, *) {
                traits.insert(.toggleButton)
            }
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.SendStarReactions_Title,
            value: count > 0 ? "\(count)" : nil,
            hint: nil,
            traits: traits
        )
    }
}

