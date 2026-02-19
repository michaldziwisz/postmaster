import Foundation
import TelegramPresentationData
import UIKit

public enum ChatMessagePollBubbleContentNodeVoiceOver {
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
    
    public enum Kind: Equatable {
        case poll
        case quiz
    }
    
    public enum Action: Equatable {
        case submitVote
        case viewResults
    }
    
    public struct OptionResult: Equatable {
        public let percent: Int
        public let count: Int32
        
        public init(percent: Int, count: Int32) {
            self.percent = percent
            self.count = count
        }
    }
    
    public static func resolveOption(
        strings: PresentationStrings,
        kind: Kind,
        optionText: String,
        isMultipleAnswers: Bool,
        isSelected: Bool,
        result: OptionResult?,
        isEnabled: Bool
    ) -> Resolved {
        let label = optionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var traits: UIAccessibilityTraits = []
        var value: String?
        
        if let result {
            traits.insert(.staticText)
            
            var parts: [String] = []
            parts.append("\(result.percent)%")
            
            let countPart: String
            switch kind {
            case .poll:
                countPart = result.count == 0 ? strings.MessagePoll_NoVotes : strings.MessagePoll_VotedCount(result.count)
            case .quiz:
                countPart = result.count == 0 ? strings.MessagePoll_QuizNoUsers : strings.MessagePoll_QuizCount(result.count)
            }
            parts.append(countPart)
            
            if isSelected {
                parts.append(strings.VoiceOver_Chat_OptionSelected)
            }
            
            value = parts.joined(separator: ", ")
        } else {
            traits.insert(.button)
            
            if isMultipleAnswers {
                if #available(iOS 17.0, *) {
                    traits.insert(.toggleButton)
                }
                if isSelected {
                    traits.insert(.selected)
                }
            }
            
            if !isEnabled {
                traits.insert(.notEnabled)
            }
        }
        
        return Resolved(label: label, value: value, hint: nil, traits: traits)
    }
    
    public static func resolveActionButton(strings: PresentationStrings, action: Action, isEnabled: Bool) -> Resolved {
        let label: String
        switch action {
        case .submitVote:
            label = strings.MessagePoll_SubmitVote
        case .viewResults:
            label = strings.MessagePoll_ViewResults
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(label: label, value: nil, hint: nil, traits: traits)
    }
    
    public static func resolveSolutionButton(strings: PresentationStrings, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(label: strings.CreatePoll_ExplanationHeader, value: nil, hint: nil, traits: traits)
    }
}

