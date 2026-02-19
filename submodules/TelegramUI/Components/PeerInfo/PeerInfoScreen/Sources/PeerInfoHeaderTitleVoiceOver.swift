import TelegramPresentationData
import UIKit

public enum PeerInfoHeaderTitleVoiceOver {
    public enum CredibilityStatus: Equatable {
        case none
        case premium
        case verified
        case fake
        case scam
    }
    
    public enum CustomActionKind: Equatable {
        case showPremiumIntro
        case showEmojiStatusIntro
        case openUniqueGift
    }
    
    public struct CustomAction: Equatable {
        public let name: String
        public let kind: CustomActionKind
        
        public init(name: String, kind: CustomActionKind) {
            self.name = name
            self.kind = kind
        }
    }
    
    public struct Resolved: Equatable {
        public let value: String?
        public let traits: UIAccessibilityTraits
        public let customActions: [CustomAction]
        
        public init(value: String?, traits: UIAccessibilityTraits, customActions: [CustomAction]) {
            self.value = value
            self.traits = traits
            self.customActions = customActions
        }
    }
    
    public static func resolve(strings: PresentationStrings, credibility: CredibilityStatus, hasEmojiStatus: Bool, hasUniqueGift: Bool) -> Resolved {
        var valueParts: [String] = []
        var customActions: [CustomAction] = []
        
        switch credibility {
        case .none:
            break
        case .premium:
            valueParts.append(strings.Premium_Title)
            customActions.append(CustomAction(name: strings.Premium_Title, kind: .showPremiumIntro))
        case .verified:
            valueParts.append("Verified")
        case .fake:
            valueParts.append(strings.Message_FakeAccount)
        case .scam:
            valueParts.append(strings.Message_ScamAccount)
        }
        
        if hasEmojiStatus {
            valueParts.append(strings.Premium_EmojiStatus)
            if hasUniqueGift {
                customActions.append(CustomAction(name: strings.Gift_View_ViewUpgraded, kind: .openUniqueGift))
            } else {
                customActions.append(CustomAction(name: strings.Premium_EmojiStatus, kind: .showEmojiStatusIntro))
            }
        }
        
        let value = valueParts.isEmpty ? nil : valueParts.joined(separator: ", ")
        var traits: UIAccessibilityTraits = [.staticText]
        traits.insert(.header)
        
        return Resolved(value: value, traits: traits, customActions: customActions)
    }
}

