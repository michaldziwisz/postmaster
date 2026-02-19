import ItemListUI
import TelegramPresentationData
import UIKit

public enum PeerInfoScreenSwitchItemVoiceOver {
    public struct Resolved: Equatable {
        public let value: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(value: String, hint: String?, traits: UIAccessibilityTraits) {
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, isOn: Bool, isLocked: Bool, isEnabled: Bool) -> Resolved {
        let value = isOn ? strings.VoiceOver_Common_On : strings.VoiceOver_Common_Off
        
        if !isEnabled {
            return Resolved(value: value, hint: nil, traits: [.staticText])
        }
        
        if isLocked {
            let rowResolved = PeerInfoScreenListRowVoiceOver.resolve(strings: strings, kind: .open, isEnabled: true)
            return Resolved(value: value, hint: rowResolved.hint, traits: rowResolved.traits)
        } else {
            let toggleResolved = ItemListToggleVoiceOver.resolve(strings: strings, isOn: isOn, isEnabled: true)
            return Resolved(value: toggleResolved.value, hint: toggleResolved.hint, traits: toggleResolved.traits)
        }
    }
}

