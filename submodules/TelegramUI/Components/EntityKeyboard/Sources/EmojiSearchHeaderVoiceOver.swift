import Foundation
import TelegramPresentationData
import UIKit

public enum EmojiSearchHeaderVoiceOver {
    public struct Category: Equatable {
        public let id: Int64
        public let title: String
        
        public init(id: Int64, title: String) {
            self.id = id
            self.title = title
        }
    }
    
    public enum CustomActionKind: Equatable {
        case clearCategory
        case selectCategory(id: Int64)
    }
    
    public struct CustomAction: Equatable {
        public let kind: CustomActionKind
        public let name: String
        
        public init(kind: CustomActionKind, name: String) {
            self.kind = kind
            self.name = name
        }
    }
    
    public struct Resolved: Equatable {
        public let isAccessibilityElement: Bool
        public let label: String?
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        public let customActions: [CustomAction]
        
        public init(
            isAccessibilityElement: Bool,
            label: String?,
            value: String?,
            hint: String?,
            traits: UIAccessibilityTraits,
            customActions: [CustomAction]
        ) {
            self.isAccessibilityElement = isAccessibilityElement
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
            self.customActions = customActions
        }
    }
    
    public static func resolve(placeholder: String, canFocus: Bool, isTextInputActive: Bool, selectedCategory: Category?, categories: [Category], strings: PresentationStrings) -> Resolved {
        if isTextInputActive {
            return Resolved(isAccessibilityElement: false, label: nil, value: nil, hint: nil, traits: [], customActions: [])
        }
        
        var traits: UIAccessibilityTraits = [.searchField]
        if !canFocus {
            traits.insert(.notEnabled)
        }
        
        var customActions: [CustomAction] = []
        if selectedCategory != nil {
            customActions.append(CustomAction(kind: .clearCategory, name: strings.VoiceOver_EmojiSearch_ClearCategory))
        }
        for category in categories {
            customActions.append(CustomAction(kind: .selectCategory(id: category.id), name: category.title))
        }
        
        return Resolved(
            isAccessibilityElement: true,
            label: placeholder,
            value: selectedCategory?.title,
            hint: nil,
            traits: traits,
            customActions: customActions
        )
    }
}
