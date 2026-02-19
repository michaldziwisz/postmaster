import Markdown
import TelegramPresentationData
import UIKit

public enum PeerInfoRecommendedPeersUnlockTextVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, isBots: Bool) -> Resolved {
        let markdownText = isBots ? strings.PeerInfo_SimilarBots_ShowMoreInfo : strings.Channel_SimilarChannels_ShowMoreInfo
        let plainText = plainTextFromMarkdown(markdownText)
        return Resolved(label: plainText, hint: nil, traits: [.staticText])
    }
    
    private static func plainTextFromMarkdown(_ text: String) -> String {
        let font = UIFont.systemFont(ofSize: 17.0)
        let color = UIColor.black
        let markdownAttributes = MarkdownAttributes(
            body: MarkdownAttributeSet(font: font, textColor: color),
            bold: MarkdownAttributeSet(font: font, textColor: color),
            link: MarkdownAttributeSet(font: font, textColor: color),
            linkAttribute: { _ in nil }
        )
        return parseMarkdownIntoAttributedString(text, attributes: markdownAttributes).string
    }
}

