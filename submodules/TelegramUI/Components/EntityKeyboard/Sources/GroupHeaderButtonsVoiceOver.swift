import Foundation
import UIKit

public enum GroupHeaderButtonsVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let traits: UIAccessibilityTraits
        
        public init(label: String, traits: UIAccessibilityTraits) {
            self.label = label
            self.traits = traits
        }
    }
    
    public static func resolve(title: String) -> Resolved {
        return Resolved(label: title, traits: [.button])
    }
}

