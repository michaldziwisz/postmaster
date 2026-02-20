import TelegramPresentationData
import UIKit

public enum AuthorizationSequencePhoneEntryNoticeVoiceOver {
    public struct Resolved: Equatable {
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(hint: String?, traits: UIAccessibilityTraits) {
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, hasLink: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.staticText]
        if hasLink {
            traits.insert(.link)
            if !isEnabled {
                traits.insert(.notEnabled)
            }
        }
        return Resolved(
            hint: (hasLink && isEnabled) ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits
        )
    }
}
