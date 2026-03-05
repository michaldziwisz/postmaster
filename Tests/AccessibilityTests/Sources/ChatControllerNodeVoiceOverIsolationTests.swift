@testable import TelegramUI
import UIKit
import XCTest

final class ChatControllerNodeVoiceOverIsolationTests: XCTestCase {
    private final class TrackingViewController: UIViewController {
        var didLoadView = false

        override func loadView() {
            self.didLoadView = true
            self.view = UIView()
        }
    }

    func testResolveWindowDoesNotLoadControllerView() {
        let controller = TrackingViewController()
        let overlay = UIView(frame: .zero)

        _ = ChatControllerNode.resolveVoiceOverOverlayWindow(controller: controller, overlay: overlay)

        XCTAssertFalse(controller.didLoadView)
        XCTAssertFalse(controller.isViewLoaded)
    }

    func testResolveWindowUsesOverlayWindowWhenControllerNotLoaded() {
        let controller = TrackingViewController()
        let overlay = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 10.0, height: 10.0))

        let window = UIWindow(frame: CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0))
        let root = UIViewController()
        window.rootViewController = root
        window.makeKeyAndVisible()
        root.view.addSubview(overlay)
        root.view.layoutIfNeeded()

        let resolvedWindow = ChatControllerNode.resolveVoiceOverOverlayWindow(controller: controller, overlay: overlay)

        XCTAssertTrue(resolvedWindow === window)
        XCTAssertFalse(controller.didLoadView)
        XCTAssertFalse(controller.isViewLoaded)
    }
}

