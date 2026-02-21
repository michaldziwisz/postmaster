import Foundation
import TelegramPresentationData
import UIKit

public enum ChatPinnedMessageTitlePanelVoiceOver {
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
    
    public static func resolveMain(strings: PresentationStrings, title: String, message: String?, isEnabled: Bool) -> Resolved {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let trimmedMessage = message?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMessage = (trimmedMessage?.isEmpty == false) ? trimmedMessage : nil
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: title,
            value: normalizedMessage,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits
        )
    }
    
    public static func resolveCloseButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Common_Close,
            value: nil,
            hint: nil,
            traits: traits
        )
    }
    
    public static func resolveListButton(strings: PresentationStrings, totalCount: Int, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Chat_TitlePinnedMessages(Int32(totalCount)),
            value: nil,
            hint: nil,
            traits: traits
        )
    }
    
    public static func resolveActionButton(title: String, isEnabled: Bool) -> Resolved {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: title,
            value: nil,
            hint: nil,
            traits: traits
        )
    }
}
