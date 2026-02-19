import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessageSelectionInputPanelVoiceOver {
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
    
    private static func resolveButton(label: String, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(label: label, hint: nil, traits: traits)
    }
    
    public static func resolveDeleteButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_MessageContextDelete, isEnabled: isEnabled)
    }
    
    public static func resolveReportButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_MessageContextReport, isEnabled: isEnabled)
    }
    
    public static func resolveForwardButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_MessageContextForward, isEnabled: isEnabled)
    }
    
    public static func resolveShareButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_MessageContextShare, isEnabled: isEnabled)
    }
    
    public static func resolveTagButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        resolveButton(label: strings.VoiceOver_MessageSelectionButtonTag, isEnabled: isEnabled)
    }
}

