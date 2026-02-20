import Foundation
import TelegramPresentationData
import UIKit

public enum MediaPickerGridItemVoiceOver {
    public enum Kind: Equatable {
        case photo
        case video
        case draft
    }
    
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
    
    public static func resolveItem(strings: PresentationStrings, kind: Kind, creationDate: Date?, isDownloading: Bool, isSelected: Bool) -> Resolved {
        let kindString: String
        switch kind {
        case .photo:
            kindString = strings.Message_Photo
        case .video:
            kindString = strings.Message_Video
        case .draft:
            kindString = strings.MediaEditor_Draft
        }
        
        let dateString = creationDate.flatMap { date in
            DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        }
        let label: String
        if let dateString, !dateString.isEmpty {
            label = "\(kindString) \(dateString)"
        } else {
            label = kindString
        }
        
        let hint: String?
        if isDownloading {
            hint = strings.Common_Cancel
        } else {
            hint = strings.VoiceOver_Chat_OpenHint
        }
        
        var traits: UIAccessibilityTraits = [.button, .image]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(label: label, hint: hint, traits: traits)
    }
    
    public static func resolveSelectionControl(strings: PresentationStrings, isSelected: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        return Resolved(label: strings.Common_Select, hint: nil, traits: traits)
    }
}
