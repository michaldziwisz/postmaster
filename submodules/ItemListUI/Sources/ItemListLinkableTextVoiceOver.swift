import TelegramPresentationData
import UIKit

public enum ItemListLinkableTextVoiceOver {
    public struct Resolved: Equatable {
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(hint: String?, traits: UIAccessibilityTraits) {
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, containsLink: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.staticText]
        if containsLink {
            traits.insert(.link)
        }
        return Resolved(
            hint: containsLink ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits
        )
    }
}

