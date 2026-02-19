import TelegramPresentationData
import UIKit

public struct PeerInfoScreenLabeledValueIconButtonVoiceOver {
    public enum IconKind {
        case qrCode
        case premiumGift
    }
    
    public struct Resolved {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
    }
    
    public static func resolve(strings: PresentationStrings, icon: IconKind) -> Resolved {
        switch icon {
        case .qrCode:
            return Resolved(
                label: strings.PeerInfo_QRCode_Title,
                hint: strings.VoiceOver_Chat_OpenHint,
                traits: [.button]
            )
        case .premiumGift:
            return Resolved(
                label: strings.VoiceOver_GiftPremium,
                hint: strings.VoiceOver_Chat_OpenHint,
                traits: [.button]
            )
        }
    }
}

public struct PeerInfoScreenLabeledValueExpandButtonVoiceOver {
    public struct Resolved {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
    }
    
    public static func resolve(strings: PresentationStrings, rowLabel: String) -> Resolved {
        let moreText = strings.PeerInfo_BioExpand
        let label: String
        if rowLabel.isEmpty {
            label = moreText
        } else {
            label = "\(rowLabel), \(moreText)"
        }
        return Resolved(
            label: label,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: [.button]
        )
    }
}

