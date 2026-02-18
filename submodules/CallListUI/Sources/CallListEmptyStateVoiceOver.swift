import Foundation
import TelegramPresentationData
import UIKit

public enum CallListEmptyStateVoiceOver {
    public struct ButtonResolved: Equatable {
        public var label: String
        public var hint: String?
        public var traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public struct Resolved: Equatable {
        public var text: String
        public var button: ButtonResolved
        
        public init(text: String, button: ButtonResolved) {
            self.text = text
            self.button = button
        }
    }
    
    public static func resolve(strings: PresentationStrings, isMissed: Bool) -> Resolved {
        let text: String
        if isMissed {
            text = strings.Calls_NoMissedCallsPlacehoder
        } else {
            text = strings.Calls_NoVoiceAndVideoCallsPlaceholder
        }
        
        return Resolved(
            text: text,
            button: ButtonResolved(
                label: strings.Calls_StartNewCall,
                hint: nil,
                traits: [.button]
            )
        )
    }
}

