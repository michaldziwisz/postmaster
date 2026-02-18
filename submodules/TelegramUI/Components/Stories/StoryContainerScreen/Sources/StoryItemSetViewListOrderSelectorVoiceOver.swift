import Foundation
import TelegramPresentationData
import UIKit

public enum StoryItemSetViewListOrderSelectorVoiceOver {
    public enum SortMode: Equatable {
        case repostsFirst
        case reactionsFirst
        case recentFirst
    }
    
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
    
    public static func resolve(strings: PresentationStrings, sortMode: SortMode, isChannel: Bool) -> Resolved {
        let label: String
        switch sortMode {
        case .repostsFirst:
            label = strings.Story_ViewList_ContextSortReposts
        case .reactionsFirst:
            label = strings.Story_ViewList_ContextSortReactions
        case .recentFirst:
            label = strings.Story_ViewList_ContextSortRecent
        }
        
        return Resolved(
            label: label,
            hint: isChannel ? strings.Story_ViewList_ContextSortChannelInfo : strings.Story_ViewList_ContextSortInfo,
            traits: [.button]
        )
    }
}
