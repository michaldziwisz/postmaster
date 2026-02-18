import Foundation
import TelegramPresentationData
import UIKit

public enum ChatQrCodeScreenNavigationButtonsVoiceOver {
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
    
    public static func resolveSwitchAppearance(strings: PresentationStrings, isDarkAppearance: Bool) -> Resolved {
        let label = isDarkAppearance ? strings.Conversation_Theme_SwitchToLight : strings.Conversation_Theme_SwitchToDark
        return Resolved(label: label, hint: nil, traits: [.button])
    }
}

