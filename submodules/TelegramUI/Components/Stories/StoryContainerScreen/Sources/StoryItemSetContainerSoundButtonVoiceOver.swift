import Foundation
import TelegramPresentationData
import UIKit

public enum StoryItemSetContainerSoundButtonVoiceOver {
    public struct Resolved: Equatable {
        public var label: String
        public var value: String?
        public var hint: String?
        public var traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(
        strings: PresentationStrings,
        isVideo: Bool,
        isSilentVideo: Bool,
        isMuted: Bool
    ) -> Resolved? {
        guard isVideo else {
            return nil
        }
        
        if isSilentVideo {
            return Resolved(
                label: strings.Story_TooltipVideoHasNoSound,
                value: nil,
                hint: nil,
                traits: [.button]
            )
        }
        
        return Resolved(
            label: isMuted ? strings.PeerInfo_EnableSound : strings.PeerInfo_DisableSound,
            value: isMuted ? strings.VoiceOver_Common_Off : strings.VoiceOver_Common_On,
            hint: nil,
            traits: [.button]
        )
    }
}
