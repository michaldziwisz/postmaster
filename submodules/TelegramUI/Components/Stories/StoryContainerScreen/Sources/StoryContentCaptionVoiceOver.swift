import TelegramPresentationData
import UIKit

public enum StoryContentCaptionVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, text: String, containsLink: Bool) -> Resolved {
        let label = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.staticText]
        if containsLink {
            traits.insert(.link)
        }
        
        return Resolved(
            label: label,
            hint: containsLink ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits
        )
    }
}

