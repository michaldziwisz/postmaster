import Foundation
import TelegramPresentationData
import UIKit

public enum StoryFooterPanelDeleteButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, isPending: Bool) -> Resolved {
        return Resolved(
            label: isPending ? strings.Common_Cancel : strings.Common_Delete,
            hint: nil,
            traits: [.button]
        )
    }
}
