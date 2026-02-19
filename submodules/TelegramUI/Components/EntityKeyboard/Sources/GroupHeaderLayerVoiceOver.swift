import Foundation
import TelegramPresentationData
import UIKit

public enum GroupHeaderLayerVoiceOver {
    public struct HeaderResolved: Equatable {
        public let label: String
        public let value: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.traits = traits
        }
    }
    
    public struct ClearResolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public struct Resolved: Equatable {
        public let header: HeaderResolved
        public let clear: ClearResolved?
        
        public init(header: HeaderResolved, clear: ClearResolved?) {
            self.header = header
            self.clear = clear
        }
    }
    
    public static func resolve(strings: PresentationStrings, title: String, subtitle: String?, badge: String?, isPremiumLocked: Bool, hasClear: Bool, isStickers: Bool, isEmbedded: Bool) -> Resolved {
        var valueLines: [String] = []
        if isPremiumLocked {
            valueLines.append(strings.Intents_ErrorLockedTitle)
        }
        if let subtitle, !subtitle.isEmpty {
            valueLines.append(subtitle)
        }
        if let badge, !badge.isEmpty {
            valueLines.append(badge)
        }
        
        let header = HeaderResolved(
            label: title,
            value: valueLines.isEmpty ? nil : valueLines.joined(separator: "\n"),
            traits: [.header]
        )
        
        let clear: ClearResolved?
        if hasClear {
            let label: String
            if isEmbedded {
                label = strings.VoiceOver_EmojiPager_HideSection(title).string
            } else if isStickers {
                label = strings.Stickers_ClearRecent
            } else {
                label = strings.Emoji_ClearRecent
            }
            clear = ClearResolved(label: label, hint: nil, traits: [.button])
        } else {
            clear = nil
        }
        
        return Resolved(header: header, clear: clear)
    }
}

