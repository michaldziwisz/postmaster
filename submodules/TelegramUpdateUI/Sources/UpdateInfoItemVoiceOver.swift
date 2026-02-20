import TelegramPresentationData
import UIKit

public enum UpdateInfoItemVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String, text: String, containsLink: Bool) -> Resolved {
        let parts = [title, text].compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        
        var traits: UIAccessibilityTraits = [.staticText]
        if containsLink {
            traits.insert(.link)
        }
        
        return Resolved(
            label: parts.joined(separator: ". "),
            hint: containsLink ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits
        )
    }
}

