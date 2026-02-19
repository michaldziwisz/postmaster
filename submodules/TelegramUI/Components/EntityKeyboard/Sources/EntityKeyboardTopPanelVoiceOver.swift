import Foundation
import TelegramPresentationData
import UIKit

public enum EntityKeyboardTopPanelVoiceOver {
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
    
    public static func resolveItem(label: String, isSelected: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(label: label, hint: nil, traits: traits)
    }
    
    public static func resolveStaticEmojiSegment(strings: PresentationStrings, segment: EmojiPagerContentComponent.StaticEmojiSegment, isSelected: Bool) -> Resolved {
        let label: String
        switch segment {
        case .people:
            label = strings.VoiceOver_EmojiCategory_People
        case .animalsAndNature:
            label = strings.VoiceOver_EmojiCategory_AnimalsAndNature
        case .foodAndDrink:
            label = strings.VoiceOver_EmojiCategory_FoodAndDrink
        case .activityAndSport:
            label = strings.VoiceOver_EmojiCategory_ActivityAndSport
        case .travelAndPlaces:
            label = strings.VoiceOver_EmojiCategory_TravelAndPlaces
        case .objects:
            label = strings.VoiceOver_EmojiCategory_Objects
        case .symbols:
            label = strings.VoiceOver_EmojiCategory_Symbols
        case .flags:
            label = strings.VoiceOver_EmojiCategory_Flags
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(label: label, hint: nil, traits: traits)
    }
}

