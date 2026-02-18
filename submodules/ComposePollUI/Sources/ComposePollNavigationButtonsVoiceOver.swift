import Foundation
import TelegramPresentationData
import UIKit

public enum ComposePollNavigationButtonsVoiceOver {
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
    
    public static func resolveDone(strings: PresentationStrings) -> Resolved {
        return Resolved(label: strings.Common_Done, hint: nil, traits: [.button])
    }
}

