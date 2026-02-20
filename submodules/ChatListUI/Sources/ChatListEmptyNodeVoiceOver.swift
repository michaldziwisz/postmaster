import Foundation
import TelegramPresentationData
import UIKit

public struct ChatListEmptyNodeVoiceOver {
    public struct ResolvedAnimation: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(title: String, description: String?) -> String {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let description, !description.isEmpty {
            return "\(title)\n\(description)"
        } else {
            return title
        }
    }
    
    public static func resolveAnimation(strings: PresentationStrings) -> ResolvedAnimation {
        return ResolvedAnimation(
            label: strings.VoiceOver_Chat_AnimatedSticker,
            hint: strings.VoiceOver_Chat_PlayHint,
            traits: [.button]
        )
    }
}
