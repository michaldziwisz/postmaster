import Foundation
import TelegramPresentationData
import UIKit
import ChatListTitleView

public enum StoryPeerListTitleLockVoiceOver {
    public typealias Resolved = ChatListTitleVoiceOver.Resolved
    
    public static func resolve(strings: PresentationStrings, titleText: String, isPasscodeSet: Bool, isManuallyLocked: Bool) -> Resolved {
        return ChatListTitleVoiceOver.resolve(strings: strings, titleText: titleText, isPasscodeSet: isPasscodeSet, isManuallyLocked: isManuallyLocked)
    }
}

