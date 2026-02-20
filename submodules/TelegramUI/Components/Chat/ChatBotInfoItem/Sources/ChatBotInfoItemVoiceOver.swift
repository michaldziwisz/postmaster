import TelegramPresentationData
import UIKit

public enum ChatBotInfoItemVoiceOver {
    public enum ActionKind: Equatable {
        case url
        case other
    }
    
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
    
    public static func resolve(strings: PresentationStrings, title: String, text: String, actionKind: ActionKind?) -> Resolved {
        let parts: [String] = [title, text].compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        var traits: UIAccessibilityTraits = [.staticText]
        let hint: String?
        
        switch actionKind {
        case .url:
            traits.insert(.link)
            hint = strings.VoiceOver_Chat_OpenLinkHint
        case .other:
            hint = strings.VoiceOver_Chat_OpenHint
        case nil:
            hint = nil
        }
        
        return Resolved(
            label: parts.joined(separator: ". "),
            hint: hint,
            traits: traits
        )
    }
}

