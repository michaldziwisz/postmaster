import Foundation
import TelegramPresentationData
import UIKit

public enum PeerInfoSubtitleBadgeVoiceOver {
    public struct Resolved: Equatable {
        public var label: String
        public var hint: String?
        public var traits: UIAccessibilityTraits

        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }

    public static func resolve(strings: PresentationStrings, title: String) -> Resolved {
        return Resolved(
            label: title,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: [.button]
        )
    }
}

