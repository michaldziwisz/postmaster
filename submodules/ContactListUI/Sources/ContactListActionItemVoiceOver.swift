import Foundation
import TelegramPresentationData
import UIKit

public enum ContactListActionItemVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String, subtitle: String?) -> Resolved {
        return Resolved(
            label: title,
            value: subtitle,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: [.button]
        )
    }
}

