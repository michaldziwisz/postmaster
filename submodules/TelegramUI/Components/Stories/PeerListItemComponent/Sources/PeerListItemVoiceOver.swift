import Foundation
import TelegramPresentationData
import UIKit

public enum PeerListItemVoiceOver {
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
        title: String,
        subtitle: String?,
        selectionState: PeerListItemComponent.SelectionState,
        rightAccessory: PeerListItemComponent.RightAccessory,
        isEnabled: Bool,
        hasAction: Bool
    ) -> Resolved {
        let value = subtitle.flatMap { $0.isEmpty ? nil : $0 }
        
        var traits: UIAccessibilityTraits = []
        if hasAction {
            traits.insert(.button)
        }
        if case let .editing(isSelected, _) = selectionState, isSelected {
            traits.insert(.selected)
        } else if rightAccessory == .check {
            traits.insert(.selected)
        }
        if !isEnabled || !hasAction {
            traits.insert(.notEnabled)
        }
        
        let hint: String?
        if hasAction && isEnabled {
            if case .none = selectionState {
                hint = strings.VoiceOver_Chat_OpenHint
            } else {
                hint = nil
            }
        } else {
            hint = nil
        }
        
        return Resolved(
            label: title,
            value: value,
            hint: hint,
            traits: traits
        )
    }
}

