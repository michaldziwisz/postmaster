import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessageActionButtonsNodeVoiceOver {
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
    
    public static func resolveButton(strings: PresentationStrings, title: String, isEnabled: Bool) -> Resolved {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = trimmedTitle.isEmpty ? strings.Common_OK : trimmedTitle
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(label: label, value: nil, hint: nil, traits: traits)
    }
    
    public static func shouldActivate(isEnabled: Bool) -> Bool {
        return isEnabled
    }
}

