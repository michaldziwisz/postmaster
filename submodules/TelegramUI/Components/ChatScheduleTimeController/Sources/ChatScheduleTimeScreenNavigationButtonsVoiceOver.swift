import Foundation
import TelegramPresentationData
import UIKit

public enum ChatScheduleTimeScreenNavigationButtonsVoiceOver {
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
    
    public static func resolveClose(strings: PresentationStrings) -> Resolved {
        return Resolved(label: strings.Common_Close, hint: nil, traits: [.button])
    }
}

