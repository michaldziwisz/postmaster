@testable import ChatListUI
import TelegramCore
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListVoiceOverOverlayViewTests: XCTestCase {
    func testIncludesSearchRowByDefault() {
        let view = ChatListVoiceOverOverlayView(frame: .zero)
        view.updatePresentationData(defaultPresentationData())
        view.updateEntries([])
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 1)
    }
    
    func testLoadMoreRowAppearsWhenHoleEntryIsPresent() {
        let view = ChatListVoiceOverOverlayView(frame: .zero)
        view.updatePresentationData(defaultPresentationData())
        
        let holeIndex = EngineMessage.Index(
            id: EngineMessage.Id(peerId: EnginePeer.Id(0), namespace: 0, id: 0),
            timestamp: 1
        )
        view.updateEntries([.HoleEntry(holeIndex, theme: defaultPresentationTheme)])
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 2)
    }
    
    func testSelectingLoadMoreRowRequestsLoadMore() {
        let view = ChatListVoiceOverOverlayView(frame: .zero)
        view.updatePresentationData(defaultPresentationData())
        
        var didRequestLoadMore = false
        view.actions.requestLoadMore = {
            didRequestLoadMore = true
        }
        
        let holeIndex = EngineMessage.Index(
            id: EngineMessage.Id(peerId: EnginePeer.Id(0), namespace: 0, id: 0),
            timestamp: 1
        )
        view.updateEntries([.HoleEntry(holeIndex, theme: defaultPresentationTheme)])
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        
        if let tableView {
            view.tableView(tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        }
        
        XCTAssertTrue(didRequestLoadMore)
    }
}

