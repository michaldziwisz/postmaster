@testable import ChatListUI
import TelegramCore
import TelegramPresentationData
import UIKit
import XCTest

final class ChatListVoiceOverOverlayViewTests: XCTestCase {
    func testHasNoRowsByDefault() {
        let view = ChatListVoiceOverOverlayView(frame: .zero)
        view.updatePresentationData(defaultPresentationData())
        view.updateEntries([])
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 0)
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
        XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 1)
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
            view.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        }
        
        XCTAssertTrue(didRequestLoadMore)
    }

    func testAutoLoadMoreRequestsWhenReachingListEnd() {
        let view = ChatListVoiceOverOverlayView(frame: .zero)
        view.updatePresentationData(defaultPresentationData())

        let chatListPresentationData = ChatListPresentationData(
            theme: defaultPresentationData().theme,
            fontSize: defaultPresentationData().fontSize,
            strings: defaultPresentationData().strings,
            dateTimeFormat: defaultPresentationData().dateTimeFormat,
            nameSortOrder: defaultPresentationData().nameSortOrder,
            nameDisplayOrder: defaultPresentationData().nameDisplayOrder,
            disableAnimations: false
        )

        var didRequestLoadMoreCount = 0
        view.actions.requestLoadMore = {
            didRequestLoadMoreCount += 1
        }

        view.updateEntries((0 ..< 10).map { index in
            .AdditionalCategory(
                index: index,
                id: index,
                title: "Category \(index)",
                image: nil,
                appearance: .option(sectionTitle: nil),
                selected: false,
                presentationData: chatListPresentationData
            )
        })

        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)

        if let tableView {
            view.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 6, section: 0))
            XCTAssertEqual(didRequestLoadMoreCount, 0)

            view.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 7, section: 0))
            XCTAssertEqual(didRequestLoadMoreCount, 1)

            view.tableView(tableView, willDisplay: UITableViewCell(), forRowAt: IndexPath(row: 9, section: 0))
            XCTAssertEqual(didRequestLoadMoreCount, 1)
        }
    }
}
