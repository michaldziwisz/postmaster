import TelegramPresentationData
import TextFormat
import UIKit

public enum SecretChatKeyControllerNodeVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let url: String?
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits, url: String?) {
            self.label = label
            self.hint = hint
            self.traits = traits
            self.url = url
        }
    }
    
    public static func resolve(strings: PresentationStrings, attributedText: NSAttributedString) -> Resolved {
        let label = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        let fullRange = NSRange(location: 0, length: attributedText.length)
        
        var url: String?
        attributedText.enumerateAttribute(urlKey, in: fullRange, options: []) { value, _, stop in
            guard let value = value as? String else {
                return
            }
            url = value
            stop.pointee = ObjCBool(true)
        }
        
        var traits: UIAccessibilityTraits = [.staticText]
        let hint: String?
        if url != nil {
            traits.insert(.link)
            hint = strings.VoiceOver_Chat_OpenLinkHint
        } else {
            hint = nil
        }
        
        return Resolved(label: label, hint: hint, traits: traits, url: url)
    }
}
