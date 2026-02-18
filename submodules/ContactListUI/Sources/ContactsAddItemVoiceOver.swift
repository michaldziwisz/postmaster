import Foundation
import UIKit

public struct ContactsAddItemVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let traits: UIAccessibilityTraits
        
        public init(label: String, traits: UIAccessibilityTraits) {
            self.label = label
            self.traits = traits
        }
    }
    
    public static func resolve(label: String) -> Resolved {
        return Resolved(label: label, traits: [.button])
    }
}

