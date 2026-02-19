import TelegramPresentationData
import UIKit

public struct PeerInfoHeaderTextFieldClearButtonVoiceOver {
    public struct Resolved {
        public let isAccessibilityElement: Bool
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
    }
    
    public static func resolve(strings: PresentationStrings, isHidden: Bool) -> Resolved {
        return Resolved(
            isAccessibilityElement: !isHidden,
            label: strings.VoiceOver_Editing_ClearText,
            hint: nil,
            traits: [.button]
        )
    }
}

