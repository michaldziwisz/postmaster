import Foundation
import TelegramPresentationData
import UIKit

public enum ChatPreparedContentAccessoryPanelVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let customActions: [CustomAction]
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits, customActions: [CustomAction]) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
            self.customActions = customActions
        }
    }
    
    public struct CustomAction: Equatable {
        public enum Kind: Equatable {
            case close
            case goToOriginalMessage
        }
        
        public let kind: Kind
        public let name: String
        
        public init(kind: Kind, name: String) {
            self.kind = kind
            self.name = name
        }
    }
    
    public static func resolve(strings: PresentationStrings, label: String, value: String?, isEnabled: Bool, includesGoToOriginalMessage: Bool) -> Resolved {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedLabel = trimmedLabel.isEmpty ? label : trimmedLabel
        
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedValue = (trimmedValue?.isEmpty == false) ? trimmedValue : nil
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        var customActions: [CustomAction] = [
            CustomAction(kind: .close, name: strings.VoiceOver_DiscardPreparedContent)
        ]
        if includesGoToOriginalMessage {
            customActions.append(CustomAction(kind: .goToOriginalMessage, name: strings.VoiceOver_Chat_GoToOriginalMessage))
        }
        
        return Resolved(
            label: resolvedLabel,
            value: resolvedValue,
            hint: isEnabled ? strings.VoiceOver_Chat_OpenHint : nil,
            traits: traits,
            customActions: customActions
        )
    }
}

