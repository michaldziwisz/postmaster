import Foundation
import UIKit

public enum ChatToastAlertPanelVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let traits: UIAccessibilityTraits
        
        public init(label: String, traits: UIAccessibilityTraits) {
            self.label = label
            self.traits = traits
        }
    }
    
    public static func resolve(text: String) -> Resolved {
        Resolved(
            label: text.trimmingCharacters(in: .whitespacesAndNewlines),
            traits: [.staticText]
        )
    }
}

