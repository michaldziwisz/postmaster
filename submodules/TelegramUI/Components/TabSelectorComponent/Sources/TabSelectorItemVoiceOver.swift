import Foundation
import UIKit

public enum TabSelectorItemVoiceOver {
    public struct Resolved: Equatable {
        public var label: String
        public var hint: String?
        public var traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(title: String, isSelected: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: title,
            hint: nil,
            traits: traits
        )
    }
}
