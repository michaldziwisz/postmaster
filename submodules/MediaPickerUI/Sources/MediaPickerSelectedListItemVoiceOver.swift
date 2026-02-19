import Foundation
import TelegramPresentationData
import UIKit

public enum MediaPickerSelectedListItemVoiceOver {
    public enum Kind: Equatable {
        case photo
        case video
    }
    
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let customActions: [CustomAction]
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits, customActions: [CustomAction]) {
            self.label = label
            self.hint = hint
            self.traits = traits
            self.customActions = customActions
        }
    }
    
    public struct SelectionControlResolved: Equatable {
        public let label: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.hint = hint
            self.traits = traits
        }
    }
    
    public struct CustomAction: Equatable {
        public enum Kind: Equatable {
            case delete
        }
        
        public let kind: Kind
        public let name: String
        
        public init(kind: Kind, name: String) {
            self.kind = kind
            self.name = name
        }
    }
    
    public static func resolve(strings: PresentationStrings, kind: Kind, creationDate: Date?, isSelected: Bool) -> Resolved {
        let kindString: String
        switch kind {
        case .photo:
            kindString = strings.Message_Photo
        case .video:
            kindString = strings.Message_Video
        }
        
        let dateString = creationDate.flatMap { date in
            DateFormatter.localizedString(from: date, dateStyle: .abbreviated, timeStyle: .standard)
        }
        
        let label: String
        if let dateString, !dateString.isEmpty {
            label = "\(kindString) \(dateString)"
        } else {
            label = kindString
        }
        
        var traits: UIAccessibilityTraits = [.button, .image]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(
            label: label,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: traits,
            customActions: [
                CustomAction(kind: .delete, name: strings.Common_Delete)
            ]
        )
    }
    
    public static func resolveSelectionControl(strings: PresentationStrings, isSelected: Bool) -> SelectionControlResolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        return SelectionControlResolved(label: strings.Common_Select, hint: nil, traits: traits)
    }
}

