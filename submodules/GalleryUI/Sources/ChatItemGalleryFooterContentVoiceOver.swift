import TelegramPresentationData
import TextFormat
import UIKit

public enum ChatItemGalleryFooterContentVoiceOver {
    public enum ActionKind: Equatable {
        case url
        case other
    }
    
    public struct LinkAction: Equatable {
        public let title: String
        public let url: String
        public let index: Int
        
        public init(title: String, url: String, index: Int) {
            self.title = title
            self.url = url
            self.index = index
        }
    }
    
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let actionKind: ActionKind?
        public let linkActions: [LinkAction]
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits, actionKind: ActionKind?, linkActions: [LinkAction]) {
            self.label = label
            self.hint = hint
            self.traits = traits
            self.actionKind = actionKind
            self.linkActions = linkActions
        }
    }
    
    public static func resolve(strings: PresentationStrings, attributedText: NSAttributedString) -> Resolved {
        let fullRange = NSRange(location: 0, length: attributedText.length)
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        
        var linkActions: [LinkAction] = []
        var seenLinkKeys = Set<String>()
        attributedText.enumerateAttribute(urlKey, in: fullRange, options: []) { value, range, _ in
            guard let url = value as? String else {
                return
            }
            let title = (attributedText.string as NSString)
                .substring(with: range)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else {
                return
            }
            let key = "\(title)\n\(url)"
            guard !seenLinkKeys.contains(key) else {
                return
            }
            seenLinkKeys.insert(key)
            linkActions.append(LinkAction(title: title, url: url, index: range.location))
        }
        
        let actionKind: ActionKind?
        if !linkActions.isEmpty {
            actionKind = .url
        } else {
            let peerMentionKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerMention)
            let peerTextMentionKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerTextMention)
            let botCommandKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.BotCommand)
            let hashtagKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag)
            let timecodeKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Timecode)
            
            var hasAction = false
            attributedText.enumerateAttributes(in: fullRange, options: []) { attributes, _, stop in
                if attributes[peerMentionKey] is TelegramPeerMention
                    || attributes[peerTextMentionKey] is String
                    || attributes[botCommandKey] is String
                    || attributes[hashtagKey] is TelegramHashtag
                    || attributes[timecodeKey] is TelegramTimecode {
                    hasAction = true
                    stop.pointee = ObjCBool(true)
                }
            }
            actionKind = hasAction ? .other : nil
        }
        
        let label = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = [.staticText]
        let hint: String?
        
        switch actionKind {
        case .url:
            traits.insert(.link)
            hint = strings.VoiceOver_Chat_OpenLinkHint
        case .other:
            hint = strings.VoiceOver_Chat_OpenHint
        case nil:
            hint = nil
        }
        
        return Resolved(
            label: label,
            hint: hint,
            traits: traits,
            actionKind: actionKind,
            linkActions: linkActions
        )
    }
}
