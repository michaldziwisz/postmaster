import Foundation
import TelegramPresentationData
import UIKit

public enum EntityKeyboardBottomPanelVoiceOver {
    public struct TabResolved: Equatable {
        public let traits: UIAccessibilityTraits
        
        public init(traits: UIAccessibilityTraits) {
            self.traits = traits
        }
    }
    
    public static func resolveTab(isSelected: Bool) -> TabResolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        return TabResolved(traits: traits)
    }
    
    public enum AccessoryButtonKind: Equatable {
        case switchToKeyboard
        case addImage
        case settings
        case deleteBackwards
    }
    
    public struct AccessoryButtonResolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolveAccessoryButton(strings: PresentationStrings, kind: AccessoryButtonKind) -> AccessoryButtonResolved {
        let label: String
        switch kind {
        case .switchToKeyboard:
            label = strings.VoiceOver_Keyboard
        case .addImage:
            label = strings.MediaPicker_AddImage
        case .settings:
            label = strings.Settings_Title
        case .deleteBackwards:
            label = strings.Common_Delete
        }
        
        return AccessoryButtonResolved(label: label, hint: nil, traits: [.button])
    }
}

