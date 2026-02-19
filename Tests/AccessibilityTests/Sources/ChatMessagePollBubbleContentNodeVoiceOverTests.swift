import ChatMessagePollBubbleContentNode
import TelegramPresentationData
import UIKit
import XCTest

final class ChatMessagePollBubbleContentNodeVoiceOverTests: XCTestCase {
    func testResolveOptionVotingSingleChoiceIsButton() {
        let resolved = ChatMessagePollBubbleContentNodeVoiceOver.resolveOption(
            strings: defaultPresentationStrings,
            kind: .poll,
            optionText: "  Option A  ",
            isMultipleAnswers: false,
            isSelected: false,
            result: nil,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, "Option A")
        XCTAssertNil(resolved.value)
        XCTAssertNil(resolved.hint)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.staticText))
    }
    
    func testResolveOptionVotingMultipleAnswersSelectedAddsSelectedTrait() {
        let resolved = ChatMessagePollBubbleContentNodeVoiceOver.resolveOption(
            strings: defaultPresentationStrings,
            kind: .poll,
            optionText: "Option B",
            isMultipleAnswers: true,
            isSelected: true,
            result: nil,
            isEnabled: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertTrue(resolved.traits.contains(.selected))
        
        if #available(iOS 17.0, *) {
            XCTAssertTrue(resolved.traits.contains(.toggleButton))
        }
    }
    
    func testResolveOptionResultsUsesStaticTextTraitAndValueParts() {
        let resolved = ChatMessagePollBubbleContentNodeVoiceOver.resolveOption(
            strings: defaultPresentationStrings,
            kind: .poll,
            optionText: "Option C",
            isMultipleAnswers: false,
            isSelected: false,
            result: ChatMessagePollBubbleContentNodeVoiceOver.OptionResult(percent: 42, count: 10),
            isEnabled: true
        )
        
        XCTAssertTrue(resolved.traits.contains(.staticText))
        XCTAssertFalse(resolved.traits.contains(.button))
        XCTAssertEqual(resolved.value, "42%, \(defaultPresentationStrings.MessagePoll_VotedCount(10))")
    }
    
    func testResolveOptionResultsSelectedAddsSelectedValuePart() {
        let resolved = ChatMessagePollBubbleContentNodeVoiceOver.resolveOption(
            strings: defaultPresentationStrings,
            kind: .poll,
            optionText: "Option D",
            isMultipleAnswers: false,
            isSelected: true,
            result: ChatMessagePollBubbleContentNodeVoiceOver.OptionResult(percent: 5, count: 0),
            isEnabled: true
        )
        
        XCTAssertEqual(
            resolved.value,
            "5%, \(defaultPresentationStrings.MessagePoll_NoVotes), \(defaultPresentationStrings.VoiceOver_Chat_OptionSelected)"
        )
    }
    
    func testResolveActionButtonUsesStrings() {
        let resolved = ChatMessagePollBubbleContentNodeVoiceOver.resolveActionButton(
            strings: defaultPresentationStrings,
            action: .viewResults,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.MessagePoll_ViewResults)
        XCTAssertTrue(resolved.traits.contains(.button))
        XCTAssertFalse(resolved.traits.contains(.notEnabled))
    }
    
    func testResolveSolutionButtonUsesExplanationLabel() {
        let resolved = ChatMessagePollBubbleContentNodeVoiceOver.resolveSolutionButton(
            strings: defaultPresentationStrings,
            isEnabled: true
        )
        
        XCTAssertEqual(resolved.label, defaultPresentationStrings.CreatePoll_ExplanationHeader)
        XCTAssertTrue(resolved.traits.contains(.button))
    }
}

