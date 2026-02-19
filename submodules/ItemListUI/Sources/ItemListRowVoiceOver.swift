import TelegramPresentationData
import UIKit

public enum ItemListRowVoiceOver {
    public enum Kind: Equatable {
        case action
        case open
        case staticText
    }
    
    public struct Resolved: Equatable {
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(hint: String?, traits: UIAccessibilityTraits) {
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, kind: Kind, isEnabled: Bool) -> Resolved {
        switch kind {
        case .staticText:
            return Resolved(hint: nil, traits: [.staticText])
        case .action:
            var traits: UIAccessibilityTraits = [.button]
            if !isEnabled {
                traits.insert(.notEnabled)
            }
            return Resolved(hint: nil, traits: traits)
        case .open:
            var traits: UIAccessibilityTraits = [.button]
            if !isEnabled {
                traits.insert(.notEnabled)
            }
            return Resolved(hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil, traits: traits)
        }
    }
}

