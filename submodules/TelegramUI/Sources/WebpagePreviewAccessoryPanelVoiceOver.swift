import Foundation
import TelegramPresentationData
import UIKit

public enum WebpagePreviewAccessoryPanelVoiceOver {
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
        }
        
        public let kind: Kind
        public let name: String
        
        public init(kind: Kind, name: String) {
            self.kind = kind
            self.name = name
        }
    }
    
    public static func resolve(strings: PresentationStrings, title: String, text: String) -> Resolved {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedTitle = trimmedTitle.isEmpty ? title : trimmedTitle
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = trimmedText.isEmpty ? nil : trimmedText
        
        return Resolved(
            label: normalizedTitle,
            value: value,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: [.button],
            customActions: [
                CustomAction(kind: .close, name: strings.VoiceOver_DiscardPreparedContent)
            ]
        )
    }
}
