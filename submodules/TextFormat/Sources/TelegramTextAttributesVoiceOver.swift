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
    
    public static func firstAction(in attributedText: NSAttributedString) -> Action? {
        guard attributedText.length > 0 else {
            return nil
        }
        
        let urlKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.URL)
        let peerMentionKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerMention)
        let peerTextMentionKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.PeerTextMention)
        let botCommandKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.BotCommand)
        let hashtagKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Hashtag)
        let timecodeKey = NSAttributedString.Key(rawValue: TelegramTextAttributes.Timecode)
        
        let fullRange = NSRange(location: 0, length: attributedText.length)
        var result: Action?
        
        attributedText.enumerateAttributes(in: fullRange, options: []) { attributes, range, stop in
            if let url = attributes[urlKey] as? String {
                let attributeText = (attributedText.string as NSString).substring(with: range)
                let concealed = !doesUrlMatchText(url: url, text: attributeText, fullText: attributedText.string)
                result = .url(url: url, concealed: concealed)
                stop.pointee = ObjCBool(true)
            } else if let peerMention = attributes[peerMentionKey] as? TelegramPeerMention {
                result = .peerMention(peerId: peerMention.peerId, mention: peerMention.mention)
                stop.pointee = ObjCBool(true)
            } else if let peerName = attributes[peerTextMentionKey] as? String {
                result = .textMention(peerName)
                stop.pointee = ObjCBool(true)
            } else if let botCommand = attributes[botCommandKey] as? String {
                result = .botCommand(botCommand)
                stop.pointee = ObjCBool(true)
            } else if let hashtag = attributes[hashtagKey] as? TelegramHashtag {
                result = .hashtag(hashtag.peerName, hashtag.hashtag)
                stop.pointee = ObjCBool(true)
            } else if let timecode = attributes[timecodeKey] as? TelegramTimecode {
                result = .timecode(timecode.time, timecode.text)
                stop.pointee = ObjCBool(true)
            }
        }
        
        return result
    }
}
