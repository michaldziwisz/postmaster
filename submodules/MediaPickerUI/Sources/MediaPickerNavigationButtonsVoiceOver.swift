import Foundation
import TelegramPresentationData
import UIKit

public enum MediaPickerNavigationButtonsVoiceOver {
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
    
    public static func resolveCancelOrBack(strings: PresentationStrings, isBack: Bool) -> Resolved {
        return Resolved(
            label: isBack ? strings.Common_Back : strings.Common_Close,
            hint: nil,
            traits: [.button]
        )
    }
    
    public static func resolveMore(strings: PresentationStrings) -> Resolved {
        return Resolved(
            label: strings.Common_More,
            hint: nil,
            traits: [.button]
        )
    }
}

