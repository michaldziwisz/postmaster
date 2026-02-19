import Foundation
import TelegramCore
import TelegramPresentationData
import UIKit

public enum ReactionButtonListComponentVoiceOver {
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
    
    public static func resolveReactionButton(
        strings: PresentationStrings,
        reaction: MessageReaction.Reaction,
        tagTitle: String?,
        customAlt: String?,
        count: Int,
        isSelected: Bool,
        isEnabled: Bool
    ) -> Resolved {
        let label: String
        if let tagTitle, !tagTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            label = tagTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            switch reaction {
            case let .builtin(value):
                label = value
            case .stars:
                label = "⭐️"
            case .custom:
                if let customAlt, !customAlt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, customAlt != "." {
                    label = customAlt.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    label = strings.PeerInfo_Reactions
                }
            }
        }
        
        let value: String?
        if count > 0 {
            value = "\(count)"
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
        
        return Resolved(label: label, value: value, hint: nil, traits: traits)
    }
}

