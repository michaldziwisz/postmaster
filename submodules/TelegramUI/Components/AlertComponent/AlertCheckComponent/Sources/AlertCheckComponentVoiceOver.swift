import Markdown
import TelegramPresentationData
import TextFormat
import UIKit

public enum AlertCheckComponentVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let traits: UIAccessibilityTraits
        public let containsLinkAction: Bool
        
        public init(label: String, traits: UIAccessibilityTraits, containsLinkAction: Bool) {
            self.label = label
            self.traits = traits
            self.containsLinkAction = containsLinkAction
        }
    }
    
    public static func resolve(strings: PresentationStrings, title: String, isSelected: Bool, linkActionAvailable: Bool) -> Resolved {
        let font = UIFont.systemFont(ofSize: 15.0)
        let boldFont = UIFont.boldSystemFont(ofSize: 15.0)
        
        let attributedText = parseMarkdownIntoAttributedString(
            title,
            attributes: MarkdownAttributes(
                body: MarkdownAttributeSet(font: font, textColor: .black),
                bold: MarkdownAttributeSet(font: boldFont, textColor: .black),
                link: MarkdownAttributeSet(font: font, textColor: .black),
                linkAttribute: { contents in
                    return (TelegramTextAttributes.URL, contents)
                }
            )
        )
        
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        let fullRange = NSRange(location: 0, length: attributedText.length)
        
        var containsLink = false
        attributedText.enumerateAttribute(urlKey, in: fullRange, options: []) { value, _, stop in
            if value != nil {
                containsLink = true
                stop.pointee = ObjCBool(true)
            }
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(
            label: attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines),
            traits: traits,
            containsLinkAction: linkActionAvailable && containsLink
        )
    }
}
