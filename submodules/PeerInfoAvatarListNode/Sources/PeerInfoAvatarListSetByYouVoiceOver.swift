import Foundation
import TelegramPresentationData
import UIKit

public enum PeerInfoAvatarListSetByYouVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String, isLink: Bool) -> Resolved {
        let traits: UIAccessibilityTraits = isLink ? [.button] : [.staticText]
        let hint: String? = isLink ? strings.VoiceOver_Chat_OpenHint : nil
        return Resolved(label: title, hint: hint, traits: traits)
    }
}

