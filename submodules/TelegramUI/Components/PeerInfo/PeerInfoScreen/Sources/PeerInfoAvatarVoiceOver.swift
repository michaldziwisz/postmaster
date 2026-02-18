import Foundation
import TelegramPresentationData
import UIKit

public enum PeerInfoAvatarVoiceOver {
    public struct Resolved: Equatable {
        public var label: String
        public var value: String?
        public var hint: String?
        public var traits: UIAccessibilityTraits

        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }

    public static func resolve(strings: PresentationStrings, peerTitle: String?, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }

        return Resolved(
            label: strings.VoiceOver_Chat_Photo,
            value: peerTitle,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}
