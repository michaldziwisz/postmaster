import Foundation
import TelegramPresentationData
import UIKit

public enum StoryFooterPanelLikeButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings) -> Resolved {
        return Resolved(
            label: strings.Story_ViewList_TitleReactions,
            hint: nil,
            traits: [.button]
        )
    }
}
