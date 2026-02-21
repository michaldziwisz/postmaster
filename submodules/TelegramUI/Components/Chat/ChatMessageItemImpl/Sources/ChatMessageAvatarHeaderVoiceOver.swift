import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessageAvatarHeaderVoiceOver {
    public enum PeerKind: Equatable {
        case user
        case group
        case channel
        case other
    }
    
    public struct Resolved: Equatable {
        public let isAccessibilityElement: Bool
        public let label: String?
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(isAccessibilityElement: Bool, label: String?, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.isAccessibilityElement = isAccessibilityElement
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, peerTitle: String?, peerKind: PeerKind, isEnabled: Bool) -> Resolved {
        let trimmedPeerTitle = peerTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPeerTitle = (trimmedPeerTitle?.isEmpty == false) ? trimmedPeerTitle : nil
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
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
        
        return Resolved(
            isAccessibilityElement: normalizedPeerTitle != nil,
            label: normalizedPeerTitle,
            value: nil,
            hint: hint,
            traits: traits
        )
    }
}
