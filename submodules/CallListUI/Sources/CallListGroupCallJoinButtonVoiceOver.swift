import Foundation
import TelegramPresentationData
import UIKit

public enum CallListGroupCallJoinButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, isActive: Bool, isEditing: Bool) -> Resolved {
        let isAccessibilityElement = !isActive && !isEditing
        if isAccessibilityElement {
            return Resolved(
                isAccessibilityElement: true,
                label: strings.VoiceChat_PanelJoin,
                hint: nil,
                traits: [.button]
            )
        } else {
            return Resolved(
                isAccessibilityElement: false,
                label: nil,
                hint: nil,
                traits: []
            )
        }
    }
}

