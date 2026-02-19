import TelegramPresentationData
import UIKit

public enum PeerInfoScreenMemberItemVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, title: String, value: String?, isEnabled: Bool) -> Resolved {
        let rowResolved = PeerInfoScreenListRowVoiceOver.resolve(strings: strings, kind: isEnabled ? .open : .staticText, isEnabled: isEnabled)
        return Resolved(label: title, value: value, hint: rowResolved.hint, traits: rowResolved.traits)
    }
}
