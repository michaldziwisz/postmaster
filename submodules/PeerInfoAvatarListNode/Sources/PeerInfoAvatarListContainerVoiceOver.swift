import Foundation
import TelegramPresentationData
import UIKit

public enum PeerInfoAvatarListContainerVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, index: Int, count: Int) -> Resolved {
        var traits: UIAccessibilityTraits = [.image]
        
        let value: String?
        if count > 0 {
            let clampedIndex = max(0, min(index, count - 1))
            value = "\(clampedIndex + 1) of \(count)"
            
            if count > 1 {
                traits.insert(.adjustable)
            }
        } else {
            value = nil
        }
        
        return Resolved(
            label: strings.VoiceOver_Chat_Photo,
            value: value,
            hint: nil,
            traits: traits
        )
    }
}

