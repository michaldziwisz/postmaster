import UIKit

public enum ItemListAdjustableVoiceOver {
    public struct Resolved: Equatable {
        public let value: String?
        public let traits: UIAccessibilityTraits
        
        public init(value: String?, traits: UIAccessibilityTraits) {
            self.value = value
            self.traits = traits
        }
    }
    
    public static func resolve(value: String?, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.adjustable]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(value: value, traits: traits)
    }
}

