import Foundation
import TelegramPresentationData
import UIKit

public enum ChatManagingBotTitlePanelVoiceOver {
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
    
    public static func resolveTitle(_ title: String) -> Resolved {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return Resolved(label: title, hint: nil, traits: [.header])
    }
    
    public static func resolveStatus(_ status: String) -> Resolved {
        let status = status.trimmingCharacters(in: .whitespacesAndNewlines)
        return Resolved(label: status, hint: nil, traits: [.staticText])
    }
    
    public static func resolveActionButton(strings: PresentationStrings, isPaused: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: isPaused ? strings.Chat_BusinessBotPanel_ActionStart : strings.Chat_BusinessBotPanel_ActionStop,
            hint: nil,
            traits: traits
        )
    }
    
    public static func resolveSettingsButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Common_More,
            hint: nil,
            traits: traits
        )
    }
}

