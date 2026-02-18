import Foundation
import UIKit

public enum NavigationSearchComponentVoiceOver {
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
    
    public static func resolveSearchField(placeholder: String) -> Resolved {
        return Resolved(label: placeholder, hint: nil, traits: [.searchField])
    }
    
    public static func resolveClearButton(clear: String) -> Resolved {
        return Resolved(label: clear, hint: nil, traits: [.button])
    }
}

