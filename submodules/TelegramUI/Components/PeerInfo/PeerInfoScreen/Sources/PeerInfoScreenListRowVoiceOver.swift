import Foundation
import TelegramPresentationData
import UIKit

public enum PeerInfoScreenListRowVoiceOver {
    public enum Kind: Equatable {
        case action
        case open
        case staticText
    }

    public struct Resolved: Equatable {
        public var hint: String?
        public var traits: UIAccessibilityTraits

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
            return Resolved(hint: strings.VoiceOver_Chat_OpenHint, traits: traits)
        }
    }
}

