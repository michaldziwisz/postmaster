import Foundation
import TelegramPresentationData
import UIKit

public enum ChatTagSearchInputPanelVoiceOver {
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
    
    public static func resolveCalendarButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.MessageCalendar_Title,
            value: nil,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
    
    public static func resolveMembersButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Conversation_SearchByName_Placeholder,
            value: nil,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
    
    public static func resolveResultsText(text: String, isToggleEnabled: Bool, strings: PresentationStrings) -> Resolved {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isToggleEnabled {
            return Resolved(
                label: text,
                value: nil,
                hint: strings.VoiceOver_Common_SwitchHint,
                traits: [.button]
            )
        } else {
            return Resolved(
                label: text,
                value: nil,
                hint: nil,
                traits: [.staticText]
            )
        }
    }
    
    public static func resolveListModeButton(strings: PresentationStrings, isDisplayingAsList: Bool, isEnabled: Bool) -> Resolved {
        let targetModeTitle = isDisplayingAsList ? strings.Chat_BottomSearchPanel_DisplayModeChat : strings.Chat_BottomSearchPanel_DisplayModeList
        let label = strings.Chat_BottomSearchPanel_DisplayModeFormat(targetModeTitle).string
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: label,
            value: nil,
            hint: isEnabled ? strings.VoiceOver_Common_SwitchHint : nil,
            traits: traits
        )
    }
}

