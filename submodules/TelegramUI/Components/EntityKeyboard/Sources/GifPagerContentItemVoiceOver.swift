import Foundation
import TelegramPresentationData
import UIKit

public enum GifPagerContentItemVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String?, description: String?) -> Resolved {
        let gifLabel = strings.Message_Animation
        
        let title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let title, !title.isEmpty {
            return Resolved(
                label: title,
                value: gifLabel,
                hint: (description?.isEmpty == false) ? description : nil,
                traits: [.button]
            )
        } else if let description, !description.isEmpty {
            return Resolved(
                label: gifLabel,
                value: description,
                hint: nil,
                traits: [.button]
            )
        } else {
            return Resolved(
                label: gifLabel,
                value: nil,
                hint: nil,
                traits: [.button]
            )
        }
    }
}
