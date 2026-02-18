import Foundation
import TelegramPresentationData
import UIKit

public enum StoryFooterPanelViewStatsVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, viewCount: Int, isEnabled: Bool) -> Resolved {
        let label: String
        if viewCount == 0 {
            label = strings.Story_Footer_NoViews
        } else {
            var string = strings.Story_Footer_ViewCount(Int32(viewCount))
            if let range = string.range(of: "|") {
                if let nextRange = string.range(of: "|", range: range.upperBound ..< string.endIndex) {
                    string.removeSubrange(string.startIndex ..< nextRange.upperBound)
                }
            }
            label = string
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: label,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
}
