import Foundation
import TelegramPresentationData
import UIKit

public enum ChatListTitleVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, titleText: String, isPasscodeSet: Bool, isManuallyLocked: Bool) -> Resolved {
        let trimmedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = trimmedTitle.isEmpty ? strings.DialogList_Title : trimmedTitle
        
        var traits: UIAccessibilityTraits = [.header]
        var hint: String?
        
        if isPasscodeSet {
            traits.insert(.button)
            hint = isManuallyLocked ? strings.DialogList_PasscodeUnlockHelp : strings.DialogList_PasscodeLockHelp
        }
        
        return Resolved(label: label, hint: hint, traits: traits)
    }
}

