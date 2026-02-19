import Foundation
import TelegramPresentationData
import UIKit

public enum EmojiPagerContentItemVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, item: EmojiPagerContentComponent.Item, isSelected: Bool) -> Resolved {
        let label: String
        
        switch item.content {
        case let .staticEmoji(emoji):
            label = emoji
        default:
            if let itemFile = item.itemFile, let alt = itemFile.customEmojiAlt, !alt.isEmpty {
                label = alt
            } else if let animationData = item.animationData {
                switch animationData.type {
                case .still:
                    label = strings.VoiceOver_Chat_Sticker
                case .lottie, .video:
                    label = strings.VoiceOver_Chat_AnimatedSticker
                }
            } else {
                label = strings.VoiceOver_Chat_Sticker
            }
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(label: label, hint: nil, traits: traits)
    }
}

