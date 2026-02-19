import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessageShareButtonVoiceOver {
    public struct Button: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public struct Resolved: Equatable {
        public let top: Button
        public let bottom: Button?
        
        public init(top: Button, bottom: Button?) {
            self.top = top
            self.bottom = bottom
        }
    }
    
    public enum Mode: Equatable {
        case share
        case comments(count: Int)
        case navigate
        case ad(hasMore: Bool)
        case summary(isExpanded: Bool)
    }
    
    public static func resolve(strings: PresentationStrings, mode: Mode) -> Resolved {
        let top: Button
        var bottom: Button?
        
        switch mode {
        case .share:
            top = Button(label: strings.VoiceOver_MessageContextShare, value: nil, hint: nil, traits: [.button])
        case let .comments(count):
            let label: String
            if count > 0 {
                label = commentsLabel(strings: strings, count: count)
            } else {
                label = strings.Conversation_TitleCommentsEmpty
            }
            top = Button(label: label, value: nil, hint: nil, traits: [.button])
        case .navigate:
            top = Button(label: strings.VoiceOver_Chat_GoToOriginalMessage, value: nil, hint: nil, traits: [.button])
        case let .ad(hasMore):
            top = Button(label: strings.Common_Close, value: nil, hint: nil, traits: [.button])
            if hasMore {
                bottom = Button(label: strings.Common_More, value: nil, hint: nil, traits: [.button])
            }
        case let .summary(isExpanded):
            var traits: UIAccessibilityTraits = [.button]
            if isExpanded {
                traits.insert(.selected)
                if #available(iOS 17.0, *) {
                    traits.insert(.toggleButton)
                }
            }
            top = Button(label: strings.Conversation_Summary_Title, value: nil, hint: nil, traits: traits)
        }
        
        return Resolved(top: top, bottom: bottom)
    }
    
    private static func commentsLabel(strings: PresentationStrings, count: Int) -> String {
        var commentsPart = strings.Conversation_MessageViewComments(Int32(count))
        if commentsPart.contains("[") && commentsPart.contains("]") {
            if let startIndex = commentsPart.firstIndex(of: "["), let endIndex = commentsPart.firstIndex(of: "]") {
                commentsPart.removeSubrange(startIndex ... endIndex)
            }
        } else {
            commentsPart = commentsPart.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789-,. "))
        }
        
        return strings.Conversation_MessageViewCommentsFormat("\(count)", commentsPart).string
    }
}

