import Foundation
import TelegramPresentationData
import UIKit

public enum StoryItemSetContainerPrivacyIconVoiceOver {
    public enum Privacy: Equatable {
        case closeFriends
        case contacts
        case selectedContacts
        case everyone
        
        init(_ privacy: StoryPrivacyIconComponent.Privacy) {
            switch privacy {
            case .closeFriends:
                self = .closeFriends
            case .contacts:
                self = .contacts
            case .selectedContacts:
                self = .selectedContacts
            case .everyone:
                self = .everyone
            }
        }
    }
    
    public struct Resolved: Equatable {
        public var label: String
        public var value: String?
        public var hint: String?
        public var traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(
        strings: PresentationStrings,
        privacy: Privacy,
        isEditable: Bool,
        peerTitle: String?
    ) -> Resolved {
        let value: String?
        switch privacy {
        case .closeFriends:
            value = strings.Story_Privacy_CategoryCloseFriends
        case .contacts:
            value = strings.Story_Privacy_CategoryContacts
        case .selectedContacts:
            value = strings.Story_Privacy_CategorySelectedContacts
        case .everyone:
            value = strings.Story_Privacy_CategoryEveryone
        }
        
        let hint: String?
        if isEditable {
            hint = strings.VoiceOver_Chat_OpenHint
        } else if let peerTitle {
            switch privacy {
            case .closeFriends:
                hint = strings.Story_TooltipPrivacyCloseFriends2(peerTitle).string
            case .contacts:
                hint = strings.Story_TooltipPrivacyContacts(peerTitle).string
            case .selectedContacts:
                hint = strings.Story_TooltipPrivacySelectedContacts(peerTitle).string
            case .everyone:
                hint = nil
            }
        } else {
            hint = nil
        }
        
        return Resolved(
            label: strings.Story_Context_Privacy,
            value: value,
            hint: hint,
            traits: [.button]
        )
    }
}
