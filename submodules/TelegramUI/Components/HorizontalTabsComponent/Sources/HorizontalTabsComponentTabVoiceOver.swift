import Foundation
import TelegramPresentationData
import UIKit

public enum HorizontalTabsComponentTabVoiceOver {
    public enum CustomAction: Equatable {
        case more(name: String)
        case delete(name: String)
    }
    
    public struct Resolved: Equatable {
        public let traits: UIAccessibilityTraits
        public let customActions: [CustomAction]
        
        public init(traits: UIAccessibilityTraits, customActions: [CustomAction]) {
            self.traits = traits
            self.customActions = customActions
        }
    }
    
    public static func resolve(strings: PresentationStrings, isSelected: Bool, hasContextAction: Bool, hasDeleteAction: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        var customActions: [CustomAction] = []
        if hasContextAction {
            customActions.append(.more(name: strings.Common_More))
        }
        if hasDeleteAction {
            customActions.append(.delete(name: strings.Common_Delete))
        }
        
        return Resolved(traits: traits, customActions: customActions)
    }
}

