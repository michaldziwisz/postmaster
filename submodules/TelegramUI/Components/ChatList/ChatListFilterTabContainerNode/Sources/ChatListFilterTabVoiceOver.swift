import TelegramPresentationData
import UIKit

public struct ChatListFilterTabItemVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, title: String, unreadCount: Int, isSelected: Bool, isEnabled: Bool) -> Resolved {
        let unreadCount = max(0, unreadCount)
        
        let value: String?
        if unreadCount > 0 {
            value = strings.VoiceOver_Chat_UnreadMessages(Int32(unreadCount))
        } else {
            value = nil
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(label: title, value: value, traits: traits)
    }
}

public struct ChatListFilterTabDeleteButtonVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, tabTitle: String) -> Resolved {
        return Resolved(
            label: strings.Common_Delete,
            value: tabTitle,
            hint: nil,
            traits: [.button]
        )
    }
}

