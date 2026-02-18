import Foundation
import TelegramPresentationData

public enum ChatHistoryNavigationButtonsVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        
        public init(label: String, value: String?, hint: String?) {
            self.label = label
            self.value = value
            self.hint = hint
        }
    }
    
    public static func resolveDown(strings: PresentationStrings, unreadCount: Int32) -> Resolved {
        return Resolved(
            label: strings.KeyCommand_ScrollDown,
            value: unreadCount > 0 ? strings.VoiceOver_Chat_UnreadMessages(unreadCount) : nil,
            hint: nil
        )
    }
    
    public static func resolveUp(strings: PresentationStrings) -> Resolved {
        return Resolved(
            label: strings.KeyCommand_ScrollUp,
            value: nil,
            hint: nil
        )
    }
    
    public static func resolveMentions(strings: PresentationStrings, mentionCount: Int32) -> Resolved {
        return Resolved(
            label: strings.Conversation_ContextMenuMention,
            value: mentionCount > 0 ? "\(mentionCount)" : nil,
            hint: strings.VoiceOver_Chat_GoToOriginalMessage
        )
    }
    
    public static func resolveReactions(strings: PresentationStrings, reactionsCount: Int32) -> Resolved {
        return Resolved(
            label: strings.PeerInfo_Reactions,
            value: reactionsCount > 0 ? "\(reactionsCount)" : nil,
            hint: strings.VoiceOver_Chat_GoToOriginalMessage
        )
    }
}

