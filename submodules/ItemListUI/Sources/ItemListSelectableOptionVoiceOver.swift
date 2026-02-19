import UIKit

public enum ItemListSelectableOptionVoiceOver {
    public struct Resolved: Equatable {
        public let value: String?
        public let traits: UIAccessibilityTraits
        
        public init(value: String?, traits: UIAccessibilityTraits) {
            self.value = value
            self.traits = traits
        }
    }
    
    public static func resolve(value: String?, isSelected: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(value: value, traits: traits)
    }
}

