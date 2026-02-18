import Foundation
import TelegramPresentationData
import UIKit

public struct ContactsPeerItemVoiceOver {
    public enum CustomAction: Equatable {
        case buttonAction(name: String)
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
    
    public static func resolve(strings: PresentationStrings, isEnabled: Bool, isSelected: Bool, buttonActionTitle: String?, isDeletable: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        if isSelected {
            traits.insert(.selected)
        }
        
        var customActions: [CustomAction] = []
        if let buttonActionTitle {
            customActions.append(.buttonAction(name: buttonActionTitle))
        }
        if isDeletable {
            customActions.append(.delete(name: strings.Common_Delete))
        }
        
        return Resolved(traits: traits, customActions: customActions)
    }
}

