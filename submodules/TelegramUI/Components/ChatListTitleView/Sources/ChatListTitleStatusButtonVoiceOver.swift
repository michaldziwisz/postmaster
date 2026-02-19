import Foundation
import TelegramPresentationData
import UIKit

public enum ChatListTitleStatusButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, status: NetworkStatusTitle.Status) -> Resolved {
        let label: String
        switch status {
        case .premium:
            label = strings.PeerInfo_SetEmojiStatus
        case .emoji:
            label = strings.PeerInfo_ChangeEmojiStatus
        }
        
        return Resolved(label: label, hint: nil, traits: [.button])
    }
}

