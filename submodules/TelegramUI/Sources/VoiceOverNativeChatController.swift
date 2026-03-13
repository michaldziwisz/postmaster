import UIKit

final class VoiceOverNativeChatController: UIViewController {
    let overlayView: ChatVoiceOverOverlayView

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let headerSeparatorView = UIView()
    private let contentView = UIView()
    private var accessibilityObservers: [NSObjectProtocol] = []
    private var keyboardDismissVoiceOverContainmentDeadline: CFTimeInterval = 0.0

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
        view.shouldGroupAccessibilityChildren = false
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
        self.contentView.shouldGroupAccessibilityChildren = false
        view.addSubview(self.contentView)

        self.overlayView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.overlayView)

        NSLayoutConstraint.activate([
            self.headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.headerView.heightAnchor.constraint(equalToConstant: 56.0),

            self.backButton.leadingAnchor.constraint(equalTo: self.headerView.leadingAnchor, constant: 8.0),
            self.backButton.topAnchor.constraint(greaterThanOrEqualTo: self.headerView.topAnchor, constant: 6.0),
            self.backButton.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor),
            self.backButton.bottomAnchor.constraint(lessThanOrEqualTo: self.headerView.bottomAnchor, constant: -6.0),
            self.backButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),

            self.infoButton.trailingAnchor.constraint(equalTo: self.headerView.trailingAnchor, constant: -8.0),
            self.infoButton.topAnchor.constraint(greaterThanOrEqualTo: self.headerView.topAnchor, constant: 6.0),
            self.infoButton.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor),
            self.infoButton.bottomAnchor.constraint(lessThanOrEqualTo: self.headerView.bottomAnchor, constant: -6.0),
            self.infoButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),

            self.titleButton.leadingAnchor.constraint(greaterThanOrEqualTo: self.backButton.trailingAnchor, constant: 8.0),
            self.titleButton.trailingAnchor.constraint(lessThanOrEqualTo: self.infoButton.leadingAnchor, constant: -8.0),
            self.titleButton.topAnchor.constraint(greaterThanOrEqualTo: self.headerView.topAnchor, constant: 6.0),
            self.titleButton.centerXAnchor.constraint(equalTo: self.headerView.centerXAnchor),
            self.titleButton.centerYAnchor.constraint(equalTo: self.headerView.centerYAnchor),
            self.titleButton.bottomAnchor.constraint(lessThanOrEqualTo: self.headerView.bottomAnchor, constant: -6.0),
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
        self.overlayView.externalNativeKeyboardEscapeHandler = { [weak self] in
            return self?.handleVoiceOverKeyboardEscape() ?? false
        }

        let focusToken = NotificationCenter.default.addObserver(forName: UIAccessibility.elementFocusedNotification, object: nil, queue: .main) { [weak self] notification in
            self?.handleVoiceOverElementFocused(notification)
        }
        self.accessibilityObservers.append(focusToken)
    }

    deinit {
        let notificationCenter = NotificationCenter.default
        self.accessibilityObservers.forEach { notificationCenter.removeObserver($0) }
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
        if self.handleVoiceOverKeyboardEscape() {
            return true
        }
        if self.overlayView.accessibilityPerformEscape() {
            return true
        }
        self.backPressed()
        return true
    }

    private func handleVoiceOverKeyboardEscape() -> Bool {
        guard self.overlayView.shouldHandleVoiceOverKeyboardEscapeExternally() else {
            return false
        }
        self.extendKeyboardDismissVoiceOverContainment(8.0)
        _ = self.overlayView.dismissKeyboardForExternalVoiceOverEscape()
        let immediateTarget = self.preferredKeyboardDismissFocusTarget()
        UIAccessibility.post(notification: .layoutChanged, argument: immediateTarget)
        self.scheduleKeyboardDismissFocusRestore(after: 0.05, remainingAttempts: 8)
        return true
    }

    private func scheduleKeyboardDismissFocusRestore(after delay: TimeInterval, remainingAttempts: Int) {
        guard UIAccessibility.isVoiceOverRunning, remainingAttempts > 0 else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else {
                return
            }
            guard self.shouldContainVoiceOverFocusAfterKeyboardDismiss else {
                return
            }
            self.restoreVoiceOverFocusAfterKeyboardDismissIfNeeded()
            self.scheduleKeyboardDismissFocusRestore(after: 0.35, remainingAttempts: remainingAttempts - 1)
        }
    }

    private func restoreVoiceOverFocusAfterKeyboardDismissIfNeeded() {
        self.reinforceNativeChatAccessibilityContainment()
        let target = self.preferredKeyboardDismissFocusTarget()
        guard self.shouldRestoreVoiceOverFocus(to: target) else {
            return
        }
        UIAccessibility.post(notification: .screenChanged, argument: target)
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: target)
        }
    }

    private func preferredKeyboardDismissFocusTarget() -> Any {
        return self.backButton
    }

    private func reinforceNativeChatAccessibilityContainment() {
        self.view.accessibilityViewIsModal = true
        self.view.accessibilityElementsHidden = false
        self.view.accessibilityElements = [
            self.backButton,
            self.titleButton,
            self.infoButton,
            self.overlayView as Any
        ]
        self.parent?.viewIfLoaded?.accessibilityViewIsModal = true
        self.navigationController?.viewIfLoaded?.accessibilityViewIsModal = true
    }

    private var shouldContainVoiceOverFocusAfterKeyboardDismiss: Bool {
        guard UIAccessibility.isVoiceOverRunning else {
            return false
        }
        return CACurrentMediaTime() < self.keyboardDismissVoiceOverContainmentDeadline
    }

    private func extendKeyboardDismissVoiceOverContainment(_ duration: TimeInterval) {
        let deadline = CACurrentMediaTime() + max(0.0, duration)
        if deadline > self.keyboardDismissVoiceOverContainmentDeadline {
            self.keyboardDismissVoiceOverContainmentDeadline = deadline
        }
    }

    private func handleVoiceOverElementFocused(_ notification: Notification) {
        guard self.shouldContainVoiceOverFocusAfterKeyboardDismiss else {
            return
        }
        let focusedElement = notification.userInfo?[UIAccessibility.focusedElementUserInfoKey]
        if self.isVoiceOverElementWithinNativeChat(focusedElement) {
            return
        }
        self.restoreVoiceOverFocusAfterKeyboardDismissIfNeeded()
    }

    private func shouldRestoreVoiceOverFocus(to target: Any) -> Bool {
        let focusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver)
        guard let focusedElement else {
            return true
        }
        if self.isSameVoiceOverElement(focusedElement, target) {
            return false
        }
        return !self.isVoiceOverElementWithinNativeChat(focusedElement)
    }

    private func isSameVoiceOverElement(_ lhs: Any, _ rhs: Any) -> Bool {
        return (lhs as AnyObject) === (rhs as AnyObject)
    }

    private func isVoiceOverElementWithinNativeChat(_ element: Any?) -> Bool {
        guard let element else {
            return false
        }
        if let view = element as? UIView {
            return view.isDescendant(of: self.view)
        }
        if let accessibilityElement = element as? UIAccessibilityElement,
           let containerView = accessibilityElement.accessibilityContainer as? UIView {
            return containerView.isDescendant(of: self.view)
        }
        return false
    }
}
