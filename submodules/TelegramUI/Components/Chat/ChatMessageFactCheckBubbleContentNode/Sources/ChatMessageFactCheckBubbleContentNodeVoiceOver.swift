import TelegramPresentationData
import UIKit

public enum ChatMessageFactCheckBubbleContentNodeVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolveBadge(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Message_FactCheck_WhatIsThis,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}

