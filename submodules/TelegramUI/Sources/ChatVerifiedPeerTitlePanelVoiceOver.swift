import Foundation
import TelegramPresentationData
import UIKit

public enum ChatVerifiedPeerTitlePanelVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, description: String, hasLink: Bool) -> Resolved {
        let description = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.staticText]
        if hasLink {
            traits.insert(.button)
        }
        
        return Resolved(
            label: description,
            hint: hasLink ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits
        )
    }
}

