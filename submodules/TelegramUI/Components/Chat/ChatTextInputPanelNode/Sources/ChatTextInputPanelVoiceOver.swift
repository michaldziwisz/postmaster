import ChatPresentationInterfaceState
import TelegramPresentationData
import TelegramStringFormatting
import UIKit

public enum ChatTextInputPanelSendAsButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, currentPeerTitle: String?, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.Conversation_SendMesageAs,
            value: currentPeerTitle,
            hint: nil,
            traits: traits
        )
    }
}

public enum ChatTextInputPanelAttachmentButtonVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let traits: UIAccessibilityTraits
        
        public init(label: String, traits: UIAccessibilityTraits) {
            self.label = label
            self.traits = traits
        }
    }
    
    public static func resolve(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(label: strings.VoiceOver_AttachMedia, traits: traits)
    }
}

public enum ChatTextInputPanelBoostToUnrestrictButtonVoiceOver {
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
    
    public static func resolve(
        strings: PresentationStrings,
        slowmodeState: ChatSlowmodeState?,
        nowTimestamp: Int32,
        isEnabled: Bool
    ) -> Resolved {
        var traits: UIAccessibilityTraits = [.button, .updatesFrequently]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        let value: String?
        if let slowmodeState {
            switch slowmodeState.variant {
            case .pendingMessages:
                value = strings.Chat_SlowmodeTooltipPending
            case let .timestamp(untilTimestamp):
                let seconds = max(Int32(0), untilTimestamp - nowTimestamp)
                value = strings.Chat_SlowmodeTooltip(stringForDuration(seconds)).string
            }
        } else {
            value = nil
        }
        
        return Resolved(
            label: strings.Conversation_BoostToUnrestrictText,
            value: value,
            hint: nil,
            traits: traits
        )
    }
}

public enum ChatTextInputPanelViewOnceButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, isSelected: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: strings.MediaPicker_Timer_ViewOnce,
            value: nil,
            hint: strings.Chat_PlayVoiceMessageOnceTooltip,
            traits: traits
        )
    }
}

public enum ChatTextInputPanelRecordMoreButtonVoiceOver {
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
    
    public static func resolve(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(label: strings.VoiceOver_Chat_RecordModeVoiceMessage, hint: nil, traits: traits)
    }
}

public enum ChatTextInputPanelTextViewVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let hint: String?
        
        public init(label: String, hint: String?) {
            self.label = label
            self.hint = hint
        }
    }
    
    public static func resolve(placeholder: String, placeholderHasStar: Bool) -> Resolved {
        let label: String
        if placeholderHasStar {
            label = placeholder.replacingOccurrences(of: "#", with: "⭐️")
        } else {
            label = placeholder
        }
        return Resolved(label: label, hint: nil)
    }
}
