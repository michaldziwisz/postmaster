import UIKit

public enum ChatRestrictedInputPanelVoiceOver {
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
    
    public static func resolve(label: String, subtitle: String?, isInteractive: Bool) -> Resolved {
        let traits: UIAccessibilityTraits = isInteractive ? [.button] : [.staticText]
        let value = (subtitle?.isEmpty ?? true) ? nil : subtitle
        return Resolved(label: label, value: value, hint: nil, traits: traits)
    }
}

