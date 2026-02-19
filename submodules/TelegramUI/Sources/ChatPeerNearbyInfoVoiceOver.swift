import Foundation
import TelegramPresentationData
import UIKit

public enum ChatPeerNearbyInfoVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, label: String, isEnabled: Bool) -> Resolved {
        let label = label.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: label,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}

