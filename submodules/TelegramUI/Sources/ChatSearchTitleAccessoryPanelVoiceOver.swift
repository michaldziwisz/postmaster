import Foundation
import TelegramPresentationData
import UIKit

public enum ChatSearchTitleAccessoryPanelVoiceOver {
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
    
    public struct CustomAction: Equatable {
        public enum Kind: Equatable {
            case editTagTitle
        }
        
        public let kind: Kind
        public let name: String
        
        public init(kind: Kind, name: String) {
            self.kind = kind
            self.name = name
        }
    }
    
    public static func resolvePromo(strings: PresentationStrings, isUnlock: Bool) -> Resolved {
        let title = isUnlock ? strings.Chat_TagsHeaderPanel_Unlock : strings.Chat_TagsHeaderPanel_AddTags
        
        return Resolved(
            label: title,
            value: isUnlock ? nil : strings.Chat_TagsHeaderPanel_AddTagsSuffix,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: [.button]
        )
    }
    
    public static func resolveItem(strings: PresentationStrings, title: String?, reactionText: String?, count: Int, isSelected: Bool, isPremium: Bool) -> Resolved {
        let trimmedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = (trimmedTitle?.isEmpty == false) ? trimmedTitle : nil
        
        let trimmedReactionText = reactionText?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedReactionText = (trimmedReactionText?.isEmpty == false) ? trimmedReactionText : nil
        
        let label = normalizedTitle ?? normalizedReactionText ?? strings.Premium_MessageTags
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        let hint: String?
        if isPremium {
            hint = strings.VoiceOver_Common_SwitchHint
        } else {
            hint = strings.VoiceOver_Chat_OpenHint
        }
        
        return Resolved(
            label: label,
            value: count > 0 ? String(count) : nil,
            hint: hint,
            traits: traits
        )
    }
    
    public static func resolveItemCustomActions(strings: PresentationStrings, hasTitle: Bool, isPremium: Bool) -> [CustomAction] {
        guard isPremium else {
            return []
        }
        
        let name = hasTitle ? strings.Chat_ReactionContextMenu_EditTagLabel : strings.Chat_ReactionContextMenu_SetTagLabel
        return [
            CustomAction(kind: .editTagTitle, name: name)
        ]
    }
}
