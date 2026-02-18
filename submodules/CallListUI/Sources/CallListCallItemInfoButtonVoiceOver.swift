import Foundation
import TelegramPresentationData
import UIKit

public enum CallListCallItemInfoButtonVoiceOver {
    public struct Resolved: Equatable {
        public var isAccessibilityElement: Bool
        public var label: String?
        public var hint: String?
        public var traits: UIAccessibilityTraits
        
        public init(isAccessibilityElement: Bool, label: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.isAccessibilityElement = isAccessibilityElement
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, isEditing: Bool) -> Resolved {
        if isEditing {
            return Resolved(isAccessibilityElement: false, label: nil, hint: nil, traits: [])
        } else {
            return Resolved(
                isAccessibilityElement: true,
                label: strings.Conversation_Info,
                hint: nil,
                traits: [.button]
            )
        }
    }
}

