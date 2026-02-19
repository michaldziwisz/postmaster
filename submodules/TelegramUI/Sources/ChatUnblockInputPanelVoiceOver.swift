import Foundation
import UIKit

public enum ChatUnblockInputPanelVoiceOver {
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
    
    public static func resolve(label: String, isEnabled: Bool) -> Resolved {
        let label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: label,
            hint: nil,
            traits: traits
        )
    }
}

