import Foundation
import TelegramPresentationData
import UIKit

public enum ChatChannelSubscriberInputPanelVoiceOver {
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
    
    private static func resolveButton(label: String, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(label: label, hint: nil, traits: traits)
    }
    
    public static func resolveGiftButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_GiftPremium, isEnabled: isEnabled)
    }
    
    public static func resolveSuggestPostButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_SuggestPost, isEnabled: isEnabled)
    }
    
    public static func resolveHelpButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.UserInfo_BotHelp, isEnabled: isEnabled)
    }
    
    public static func resolveSearchButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.Common_Search, isEnabled: isEnabled)
    }
    
    public static func resolveCenterAction(title: String, isEnabled: Bool) -> Resolved {
        resolveButton(label: title.trimmingCharacters(in: .whitespacesAndNewlines), isEnabled: isEnabled)
    }
}

