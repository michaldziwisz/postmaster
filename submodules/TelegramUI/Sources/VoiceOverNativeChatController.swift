import UIKit

final class VoiceOverNativeChatController: UIViewController {
    let overlayView: ChatVoiceOverOverlayView

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let headerSeparatorView = UIView()
    private let contentView = UIView()

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
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        view.accessibilityViewIsModal = true
        self.view = view

        self.headerView.translatesAutoresizingMaskIntoConstraints = false
        self.headerView.backgroundColor = .systemBackground
        self.headerView.isAccessibilityElement = false
        self.headerView.shouldGroupAccessibilityChildren = false
        view.addSubview(self.headerView)

        self.backButton.translatesAutoresizingMaskIntoConstraints = false
        self.backButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.backButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.backButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 10.0, bottom: 8.0, right: 10.0)
        self.backButton.setContentHuggingPriority(.required, for: .horizontal)
        self.backButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.headerView.addSubview(self.backButton)

        self.titleButton.translatesAutoresizingMaskIntoConstraints = false
        self.titleButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        self.titleButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.titleButton.titleLabel?.lineBreakMode = .byTruncatingTail
        self.titleButton.setTitleColor(.label, for: .normal)
        self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 10.0, bottom: 8.0, right: 10.0)
        self.titleButton.accessibilityTraits = [.button, .header]
        self.headerView.addSubview(self.titleButton)

        self.infoButton.translatesAutoresizingMaskIntoConstraints = false
        self.infoButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.infoButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.infoButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 10.0, bottom: 8.0, right: 10.0)
        self.infoButton.setContentHuggingPriority(.required, for: .horizontal)
        self.infoButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.headerView.addSubview(self.infoButton)

        self.headerSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        self.headerSeparatorView.backgroundColor = UIColor.separator
        self.headerSeparatorView.isAccessibilityElement = false
        self.headerView.addSubview(self.headerSeparatorView)

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.backgroundColor = .clear
        self.contentView.isAccessibilityElement = false
        view.addSubview(self.contentView)

        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.overlayView)

        NSLayoutConstraint.activate([
            self.headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56.0),

            self.backButton.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 8.0),
            self.backButton.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor),
            self.backButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),

            self.infoButton.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -8.0),
            self.infoButton.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor),
            self.infoButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),

            self.titleButton.leadingAnchor.constraint(greaterThanOrEqualTo: self.backButton.trailingAnchor, constant: 8.0),
            self.titleButton.trailingAnchor.constraint(lessThanOrEqualTo: self.infoButton.leadingAnchor, constant: -8.0),
            self.titleButton.centerXAnchor.constraint(equalTo: self.headerView.centerXAnchor),
            self.titleButton.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor),
            self.titleButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),

            self.headerSeparatorView.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor),
            self.headerSeparatorView.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor),
            self.headerSeparatorView.bottomAnchor.constraint(equalTo: self.headerView.bottomAnchor),
            self.headerSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            self.contentView.topAnchor.constraint(equalTo: self.headerView.bottomAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            self.overlayView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.overlayView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.overlayView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.overlayView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.backButton.addTarget(self, action: #selector(self.backPressed), for: .touchUpInside)
        self.titleButton.addTarget(self, action: #selector(self.infoPressed), for: .touchUpInside)
        self.infoButton.addTarget(self, action: #selector(self.infoPressed), for: .touchUpInside)

        self.applyNavigationState(ChatVoiceOverOverlayView.NativeNavigationState(
            title: "",
            backTitle: "Back",
            infoLabel: "Chat info",
            infoHint: nil
        ))

        self.overlayView.onNativeNavigationStateUpdated = { [weak self] state in
            self?.applyNavigationState(state)
        }
        self.overlayView.externalNavigationFocusTargetProvider = { [weak self] in
            return self?.backButton
        }
        self.overlayView.externalProfileFocusTargetProvider = { [weak self] in
            return self?.titleButton
        }
    }

    private func applyNavigationState(_ state: ChatVoiceOverOverlayView.NativeNavigationState) {
        self.backButton.setTitle(state.backTitle, for: .normal)
        self.backButton.accessibilityLabel = state.backTitle

        let resolvedTitle = state.title.isEmpty ? state.infoLabel : state.title
        self.titleButton.setTitle(resolvedTitle, for: .normal)
        self.titleButton.accessibilityLabel = resolvedTitle
        self.titleButton.accessibilityHint = state.infoHint

        self.infoButton.setTitle(state.infoLabel, for: .normal)
        self.infoButton.accessibilityLabel = state.infoLabel
        self.infoButton.accessibilityHint = state.infoHint

        self.view.accessibilityElements = [
            self.backButton,
            self.titleButton,
            self.infoButton,
            self.overlayView as Any
        ]
    }

    @objc private func backPressed() {
        self.overlayView.actions.back?()
    }

    @objc private func infoPressed() {
        self.overlayView.actions.openProfile?()
    }

    func setAccessibilityModalState(_ isModal: Bool) {
        self.view.accessibilityViewIsModal = isModal
        self.view.accessibilityElementsHidden = !isModal
    }

    override func accessibilityPerformEscape() -> Bool {
        if self.overlayView.accessibilityPerformEscape() {
            return true
        }
        self.backPressed()
        return true
    }
}
