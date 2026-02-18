import Foundation
import TelegramPresentationData
import UIKit

public enum ChatTitleViewVoiceOver {
    public enum PeerKind: Equatable {
        case user
        case group
        case channel
        case other
    }
    
    public struct Resolved: Equatable {
        public let traits: UIAccessibilityTraits
        public let hint: String?
        
        public init(traits: UIAccessibilityTraits, hint: String?) {
            self.traits = traits
            self.hint = hint
        }
    }
    
    public static func resolve(strings: PresentationStrings, isEnabled: Bool, peerKind: PeerKind) -> Resolved {
        var traits: UIAccessibilityTraits = [.header]
        if isEnabled {
            traits.insert(.button)
        } else {
            traits.insert(.notEnabled)
        }
        
        let hint: String?
        if isEnabled {
            switch peerKind {
            case .user:
                hint = strings.VoiceOver_Chat_Profile
            case .group:
                hint = strings.VoiceOver_Chat_GroupInfo
            case .channel:
                hint = strings.VoiceOver_Chat_ChannelInfo
            case .other:
                hint = nil
            }
        } else {
            hint = nil
        }
        
        return Resolved(traits: traits, hint: hint)
    }
}

