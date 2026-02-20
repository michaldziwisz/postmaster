import UIKit

public enum LargeEmojiActionSheetItemVoiceOver {
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
    
    public static func resolve(text: String) -> Resolved {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = trimmed.isEmpty ? text : trimmed
        return Resolved(label: label, hint: nil, traits: [.button, .image])
    }
}

