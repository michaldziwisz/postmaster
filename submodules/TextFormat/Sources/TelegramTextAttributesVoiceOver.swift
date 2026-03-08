import Foundation
import TelegramCore
import UrlEscaping

public enum TelegramTextAttributesVoiceOver {
    public enum Action: Equatable {
        case url(url: String, concealed: Bool)
        case peerMention(peerId: EnginePeer.Id, mention: String)
        case textMention(String)
        case botCommand(String)
        case hashtag(String?, String)
        case timecode(Double, String)
    }

    public struct Item: Equatable {
        public let action: Action
        public let text: String
        public let range: NSRange

        public init(action: Action, text: String, range: NSRange) {
            self.action = action
            self.text = text
            self.range = range
        }
    }

    public static func firstAction(in attributedText: NSAttributedString) -> Action? {
        guard attributedText.length > 0 else {
            return nil
        }
        return self.items(in: attributedText).first?.action
    }

    public static func items(in attributedText: NSAttributedString) -> [Item] {
        guard attributedText.length > 0 else {
            return []
        }

        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        let peerMentionKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerMention)
        let peerTextMentionKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerTextMention)
        let botCommandKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.BotCommand)
        let hashtagKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag)
        let timecodeKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Timecode)

        let fullRange = NSRange(location: 0, length: attributedText.length)
        var result: [Item] = []

        attributedText.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let attributeText = (attributedText.string as NSString).substring(with: range)
            if let url = attributes[urlKey] as? String {
                let concealed = !doesUrlMatchText(url: url, text: attributeText, fullText: attributedText.string)
                result.append(Item(action: .url(url: url, concealed: concealed), text: attributeText, range: range))
            } else if let peerMention = attributes[peerMentionKey] as? TelegramPeerMention {
                result.append(Item(action: .peerMention(peerId: peerMention.peerId, mention: peerMention.mention), text: attributeText, range: range))
            } else if let peerName = attributes[peerTextMentionKey] as? String {
                result.append(Item(action: .textMention(peerName), text: attributeText, range: range))
            } else if let botCommand = attributes[botCommandKey] as? String {
                result.append(Item(action: .botCommand(botCommand), text: attributeText, range: range))
            } else if let hashtag = attributes[hashtagKey] as? TelegramHashtag {
                result.append(Item(action: .hashtag(hashtag.peerName, hashtag.hashtag), text: attributeText, range: range))
            } else if let timecode = attributes[timecodeKey] as? TelegramTimecode {
                result.append(Item(action: .timecode(timecode.time, timecode.text), text: attributeText, range: range))
            }
        }

        return result
    }
}
