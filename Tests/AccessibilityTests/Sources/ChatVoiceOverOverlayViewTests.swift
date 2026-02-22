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
}
