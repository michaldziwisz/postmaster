@testable import TelegramUI
import Postbox
import XCTest

final class ChatHistoryListNodeVoiceOverLoadEarlierTests: XCTestCase {
    func testEarlierIdWinsOverHoleEarlier() {
        let earlierId = MessageIndex(id: MessageId(peerId: PeerId(1), namespace: 0, id: 50), timestamp: 10)
        let oldestIndex = MessageIndex(id: MessageId(peerId: PeerId(1), namespace: 0, id: 100), timestamp: 20)
        
        let result = ChatHistoryListNodeImpl.voiceOverRequestedIndexForLoadEarlier(
            earlierId: earlierId,
            holeEarlier: true,
            oldestIndex: oldestIndex
        )
        
        guard case let .message(index) = result else {
            XCTFail("Expected .message")
            return
        }
        XCTAssertEqual(index, earlierId)
    }
    
    func testHoleEarlierAnchorsInsideHoleUsingPredecessor() {
        let oldestIndex = MessageIndex(id: MessageId(peerId: PeerId(1), namespace: 0, id: 100), timestamp: 20)
        
        let result = ChatHistoryListNodeImpl.voiceOverRequestedIndexForLoadEarlier(
            earlierId: nil,
            holeEarlier: true,
            oldestIndex: oldestIndex
        )
        
        guard case let .message(index) = result else {
            XCTFail("Expected .message")
            return
        }
        XCTAssertEqual(index, oldestIndex.peerLocalPredecessor())
    }
    
    func testNoOldestFallsBackToLowerBound() {
        let result = ChatHistoryListNodeImpl.voiceOverRequestedIndexForLoadEarlier(
            earlierId: nil,
            holeEarlier: true,
            oldestIndex: nil
        )
        
        switch result {
        case .lowerBound:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .lowerBound")
        }
    }
    
    func testOldestIsUsedWhenNoHoleAndNoEarlierId() {
        let oldestIndex = MessageIndex(id: MessageId(peerId: PeerId(1), namespace: 0, id: 100), timestamp: 20)
        
        let result = ChatHistoryListNodeImpl.voiceOverRequestedIndexForLoadEarlier(
            earlierId: nil,
            holeEarlier: false,
            oldestIndex: oldestIndex
        )
        
        guard case let .message(index) = result else {
            XCTFail("Expected .message")
            return
        }
        XCTAssertEqual(index, oldestIndex)
    }
}

