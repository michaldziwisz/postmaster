import TelegramPresentationData
import TextFormat
import UIKit

public enum InstantPageTextItemVoiceOver {
    public struct LinkAction: Equatable {
        public let title: String
        public let value: InstantPageUrlItem
        
        public init(title: String, value: InstantPageUrlItem) {
            self.title = title
            self.value = value
        }
    }
    
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let linkActions: [LinkAction]
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits, linkActions: [LinkAction]) {
            self.label = label
            self.hint = hint
            self.traits = traits
            self.linkActions = linkActions
        }
    }
    
    public static func resolve(strings: PresentationStrings, attributedText: NSAttributedString) -> Resolved {
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        let fullRange = NSRange(location: 0, length: attributedText.length)
        
        var linkActions: [LinkAction] = []
        var seenLinkKeys = Set<String>()
        attributedText.enumerateAttribute(urlKey, in: fullRange, options: []) { value, range, _ in
            guard let value = value as? InstantPageUrlItem else {
                return
            }
            let title = (attributedText.string as NSString)
                .substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else {
                return
            }
            let key = "\(title)\n\(value.url)"
            guard !seenLinkKeys.contains(key) else {
                return
            }
            seenLinkKeys.insert(key)
            linkActions.append(LinkAction(title: title, value: value))
        }
        
        let containsLink = !linkActions.isEmpty
        var traits: UIAccessibilityTraits = [.staticText]
        if containsLink {
            traits.insert(.link)
        }
        
        return Resolved(
            label: attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines),
            hint: containsLink ? strings.VoiceOver_Chat_OpenLinkHint : nil,
            traits: traits,
            linkActions: linkActions
        )
    }
}

