import TelegramPresentationData
import UIKit

public enum PeerInfoVisualMediaItemVoiceOver {
    public enum Kind: Equatable {
        case photo
        case gif
        case video(duration: String?)
        case file
    }
    
    public struct Resolved: Equatable {
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
    
    public static func resolve(strings: PresentationStrings, kind: Kind, isSelectionMode: Bool, isSelected: Bool) -> Resolved {
        let label: String
        var value: String? = nil
        
        switch kind {
        case .photo:
            label = strings.VoiceOver_Chat_Photo
        case .gif:
            label = strings.Message_Animation
        case let .video(duration):
            label = strings.VoiceOver_Chat_Video
            value = duration
        case .file:
            label = strings.VoiceOver_Chat_File
        }
        
        let hint: String? = isSelectionMode ? nil : strings.VoiceOver_Chat_OpenHint
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelectionMode, isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(label: label, value: value, hint: hint, traits: traits)
    }
}

