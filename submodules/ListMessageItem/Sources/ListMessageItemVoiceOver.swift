import Foundation
import TelegramPresentationData
import UIKit

public struct ListMessageItemVoiceOver {
    public struct Resolved: Equatable {
        public let isAccessibilityElement: Bool
        public let label: String?
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(isAccessibilityElement: Bool, label: String?, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.isAccessibilityElement = isAccessibilityElement
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, chatTitle: String?, authorName: String?, summary: String?, isSelected: Bool) -> Resolved {
        let chatTitle = chatTitle.flatMap { $0.isEmpty ? nil : $0 }
        let summary = summary.flatMap { $0.isEmpty ? nil : $0 }
        
        let value: String?
        if let authorName, !authorName.isEmpty, let summary {
            value = "\(strings.VoiceOver_ChatList_MessageFrom(authorName).string)\n\(summary)"
        } else {
            value = summary
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(
            isAccessibilityElement: chatTitle != nil,
            label: chatTitle,
            value: value,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: traits
        )
    }
}

