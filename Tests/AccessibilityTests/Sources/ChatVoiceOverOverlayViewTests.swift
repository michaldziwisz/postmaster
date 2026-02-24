import TelegramUI
import UIKit
import XCTest

final class ChatVoiceOverOverlayViewTests: XCTestCase {
    func testInitConfiguresModalAccessibilityContainer() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        XCTAssertFalse(view.isAccessibilityElement)
        XCTAssertTrue(view.accessibilityViewIsModal)
    }
    
    func testEscapeGestureExecutesBackAction() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        var didGoBack = false
        view.actions.back = {
            didGoBack = true
        }
        
        XCTAssertTrue(view.accessibilityPerformEscape())
        XCTAssertTrue(didGoBack)
    }
    
    func testHasRefreshControlOnTableView() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        XCTAssertNotNil(tableView?.refreshControl)
        XCTAssertTrue(tableView?.alwaysBounceVertical ?? false)
    }

    func testDoesNotAutoRequestLoadEarlierWhileScrolling() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        var didRequestLoadEarlier = false
        view.actions.requestLoadEarlier = {
            didRequestLoadEarlier = true
        }
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        tableView?.contentOffset = .zero
        
        if let tableView {
            view.scrollViewDidScroll(tableView)
        }
        
        XCTAssertFalse(didRequestLoadEarlier)
    }
    
    func testRequestsLoadEarlierAfterScrollingEndsNearTop() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        var didRequestLoadEarlier = false
        view.actions.requestLoadEarlier = {
            didRequestLoadEarlier = true
        }
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        tableView?.contentOffset = .zero
        
        if let tableView {
            view.scrollViewDidEndDecelerating(tableView)
        }
        
        XCTAssertTrue(didRequestLoadEarlier)
    }
    
    func testRequestsScrollToLatestAfterScrollingEndsAtBottom() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        var didRequestScrollToLatest = false
        view.actions.scrollToLatest = {
            didRequestScrollToLatest = true
        }
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        tableView?.contentOffset = CGPoint(x: 0.0, y: 1000.0)
        
        if let tableView {
            view.scrollViewDidEndDecelerating(tableView)
        }
        
        XCTAssertTrue(didRequestScrollToLatest)
    }
    
    func testLoadEarlierRowIsHiddenByDefault() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 0)
    }
    
    func testLoadEarlierRowAppearsWhenCanLoadEarlierIsTrue() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        view.updateLoadEarlierState(canLoadEarlier: true, isLoadingEarlier: false)
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        XCTAssertEqual(tableView?.numberOfRows(inSection: 0), 1)
    }
    
    func testSelectingLoadEarlierRowRequestsLoadEarlier() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        var didRequestLoadEarlier = false
        view.actions.requestLoadEarlier = {
            didRequestLoadEarlier = true
        }
        
        view.updateLoadEarlierState(canLoadEarlier: true, isLoadingEarlier: false)
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        
        if let tableView {
            view.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        }
        
        XCTAssertTrue(didRequestLoadEarlier)
    }
    
    func testLoadEarlierRowIsDisabledWhileWaitingForLoad() {
        let view = ChatVoiceOverOverlayView(frame: .zero)
        
        view.actions.requestLoadEarlier = {}
        view.updateLoadEarlierState(canLoadEarlier: true, isLoadingEarlier: false)
        
        let tableView = view.subviews.compactMap { $0 as? UITableView }.first
        XCTAssertNotNil(tableView)
        
        guard let tableView else {
            return
        }
        
        view.tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        let cell = view.tableView(tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(cell.accessibilityTraits.contains(.notEnabled))
        XCTAssertNil(view.tableView(tableView, willSelectRowAt: IndexPath(row: 0, section: 0)))
    }
}
