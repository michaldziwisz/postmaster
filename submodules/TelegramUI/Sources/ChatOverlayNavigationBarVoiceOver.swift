import Foundation
import TelegramPresentationData
import UIKit

public enum ChatOverlayNavigationBarVoiceOver {
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
    
    public static func resolveTitle(strings: PresentationStrings, title: String, isEnabled: Bool) -> Resolved {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.button, .header]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: title,
            value: nil,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
    
    public static func resolveCloseButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Common_Close,
            value: nil,
            hint: nil,
            traits: traits
        )
    }
}

