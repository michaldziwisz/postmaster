import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessageDateHeaderVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String, isActionEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.header]
        if isActionEnabled {
            traits.insert(.button)
        }
        
        return Resolved(
            label: title,
            hint: isActionEnabled ? strings.Chat_JumpToDate : nil,
            traits: traits
        )
    }
}
