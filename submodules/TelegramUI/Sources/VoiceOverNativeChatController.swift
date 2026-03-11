import UIKit

final class VoiceOverNativeChatController: UIViewController {
    let overlayView: ChatVoiceOverOverlayView

    init(overlayView: ChatVoiceOverOverlayView) {
        self.overlayView = overlayView
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationCapturesStatusBarAppearance = true
        self.definesPresentationContext = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = self.overlayView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.view.isAccessibilityElement = false
    }
}
