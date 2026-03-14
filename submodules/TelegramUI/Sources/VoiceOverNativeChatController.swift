import UIKit

private final class VoiceOverNativeChatTextView: UITextView {
    var onAccessibilityEscape: (() -> Bool)?

    override func accessibilityPerformEscape() -> Bool {
        if self.onAccessibilityEscape?() == true {
            return true
        }
        return super.accessibilityPerformEscape()
    }
}

final class VoiceOverNativeChatController: UIViewController, UITextViewDelegate {
    let overlayView: ChatVoiceOverOverlayView

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let headerSeparatorView = UIView()
    private let contentView = UIView()
    private let composerView = UIView()
    private let composerSeparatorView = UIView()
    private let attachButton = UIButton(type: .system)
    private let inputTextView = VoiceOverNativeChatTextView()
    private let primaryActionButton = UIButton(type: .system)
    private var accessibilityObservers: [NSObjectProtocol] = []
    private var keyboardObservers: [NSObjectProtocol] = []
    private var keyboardDismissVoiceOverContainmentDeadline: CFTimeInterval = 0.0
    private var primaryActionKind: PrimaryActionKind = .record
    private var composerBottomConstraint: NSLayoutConstraint?
    private var nativeComposerState = ChatVoiceOverOverlayView.NativeComposerState(
        isEnabled: true,
        isRecording: false,
        canRecord: true,
        attachLabel: "Attach",
        sendLabel: "Send",
        recordLabel: "Record",
        recordHint: nil,
        inputLabel: "Message"
    )

    private enum PrimaryActionKind {
        case send
        case record
    }

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

        self.composerView.translatesAutoresizingMaskIntoConstraints = false
        self.composerView.backgroundColor = .systemBackground
        self.composerView.isAccessibilityElement = false
        self.composerView.shouldGroupAccessibilityChildren = false
        view.addSubview(self.composerView)

        self.composerSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        self.composerSeparatorView.backgroundColor = UIColor.separator
        self.composerSeparatorView.isAccessibilityElement = false
        self.composerView.addSubview(self.composerSeparatorView)

        self.attachButton.translatesAutoresizingMaskIntoConstraints = false
        self.attachButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.attachButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.attachButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 10.0, bottom: 8.0, right: 10.0)
        self.composerView.addSubview(self.attachButton)

        self.primaryActionButton.translatesAutoresizingMaskIntoConstraints = false
        self.primaryActionButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.primaryActionButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.primaryActionButton.contentEdgeInsets = UIEdgeInsets(top: 8.0, left: 12.0, bottom: 8.0, right: 12.0)
        self.primaryActionButton.setContentHuggingPriority(.required, for: .horizontal)
        self.primaryActionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.composerView.addSubview(self.primaryActionButton)

        self.inputTextView.translatesAutoresizingMaskIntoConstraints = false
        self.inputTextView.font = UIFont.preferredFont(forTextStyle: .body)
        self.inputTextView.adjustsFontForContentSizeCategory = true
        self.inputTextView.backgroundColor = .secondarySystemBackground
        self.inputTextView.layer.cornerRadius = 10.0
        self.inputTextView.textContainerInset = UIEdgeInsets(top: 10.0, left: 8.0, bottom: 10.0, right: 8.0)
        self.inputTextView.returnKeyType = .default
        self.inputTextView.enablesReturnKeyAutomatically = false
        self.inputTextView.delegate = self
        self.composerView.addSubview(self.inputTextView)

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
            self.contentView.bottomAnchor.constraint(equalTo: self.composerView.topAnchor),

            self.composerSeparatorView.leadingAnchor.constraint(equalTo: self.composerView.leadingAnchor),
            self.composerSeparatorView.trailingAnchor.constraint(equalTo: self.composerView.trailingAnchor),
            self.composerSeparatorView.topAnchor.constraint(equalTo: self.composerView.topAnchor),
            self.composerSeparatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale),

            self.attachButton.leadingAnchor.constraint(equalTo: self.composerView.leadingAnchor, constant: 12.0),
            self.attachButton.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.attachButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44.0),
            self.attachButton.heightAnchor.constraint(equalToConstant: 44.0),

            self.primaryActionButton.trailingAnchor.constraint(equalTo: self.composerView.trailingAnchor, constant: -12.0),
            self.primaryActionButton.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.primaryActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 56.0),
            self.primaryActionButton.heightAnchor.constraint(equalToConstant: 44.0),

            self.inputTextView.leadingAnchor.constraint(equalTo: self.attachButton.trailingAnchor, constant: 8.0),
            self.inputTextView.trailingAnchor.constraint(equalTo: self.primaryActionButton.leadingAnchor, constant: -8.0),
            self.inputTextView.topAnchor.constraint(equalTo: self.composerView.topAnchor, constant: 10.0),
            self.inputTextView.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),

            self.overlayView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.overlayView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.overlayView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.overlayView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
        ])

        let composerBottomConstraint = self.composerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        self.composerBottomConstraint = composerBottomConstraint
        NSLayoutConstraint.activate([
            self.composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerBottomConstraint
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.backButton.addTarget(self, action: #selector(self.backPressed), for: .touchUpInside)
        self.titleButton.addTarget(self, action: #selector(self.infoPressed), for: .touchUpInside)
        self.infoButton.addTarget(self, action: #selector(self.infoPressed), for: .touchUpInside)
        self.attachButton.addTarget(self, action: #selector(self.attachPressed), for: .touchUpInside)
        self.primaryActionButton.addTarget(self, action: #selector(self.primaryActionPressed), for: .touchUpInside)
        self.inputTextView.onAccessibilityEscape = { [weak self] in
            return self?.handleVoiceOverKeyboardEscape() ?? false
        }

        self.applyNavigationState(ChatVoiceOverOverlayView.NativeNavigationState(
            title: "",
            backTitle: "Back",
            infoLabel: "Chat info",
            infoHint: nil
        ))
        self.applyComposerState(self.overlayView.currentNativeComposerState())
        self.overlayView.setNativeComposerHostedExternally(true)

        self.overlayView.onNativeNavigationStateUpdated = { [weak self] state in
            self?.applyNavigationState(state)
        }
        self.overlayView.onNativeComposerStateUpdated = { [weak self] state in
            self?.applyComposerState(state)
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
        self.setupKeyboardObservers()
        self.refreshAccessibilityContainers()
    }

    deinit {
        self.overlayView.setNativeComposerHostedExternally(false)
        let notificationCenter = NotificationCenter.default
        self.accessibilityObservers.forEach { notificationCenter.removeObserver($0) }
        self.keyboardObservers.forEach { notificationCenter.removeObserver($0) }
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

        self.headerView.accessibilityElements = [
            self.backButton,
            self.titleButton,
            self.infoButton
        ]
        self.refreshAccessibilityContainers()
    }

    private func applyComposerState(_ state: ChatVoiceOverOverlayView.NativeComposerState) {
        self.nativeComposerState = state
        self.composerView.isUserInteractionEnabled = state.isEnabled

        self.attachButton.setTitle("＋", for: .normal)
        self.attachButton.accessibilityLabel = state.attachLabel
        self.attachButton.accessibilityTraits = [.button]
        self.attachButton.isEnabled = state.isEnabled

        let shouldShowSend = state.isEnabled && !self.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !state.isRecording
        if shouldShowSend {
            self.primaryActionKind = .send
            self.primaryActionButton.setTitle(state.sendLabel, for: .normal)
            self.primaryActionButton.accessibilityLabel = state.sendLabel
            self.primaryActionButton.accessibilityHint = nil
            self.primaryActionButton.accessibilityTraits = [.button]
            self.primaryActionButton.isEnabled = true
        } else {
            self.primaryActionKind = .record
            self.primaryActionButton.setTitle(state.isRecording ? "■" : "●", for: .normal)
            self.primaryActionButton.accessibilityLabel = state.recordLabel
            self.primaryActionButton.accessibilityHint = state.recordHint
            self.primaryActionButton.accessibilityTraits = state.canRecord ? [.button] : [.button, .notEnabled]
            self.primaryActionButton.isEnabled = state.canRecord
        }
        self.primaryActionButton.isAccessibilityElement = true
        self.primaryActionButton.accessibilityElementsHidden = false
        self.composerView.bringSubviewToFront(self.primaryActionButton)

        self.inputTextView.isEditable = state.isEnabled
        self.inputTextView.isSelectable = state.isEnabled
        self.inputTextView.isUserInteractionEnabled = state.isEnabled
        self.inputTextView.accessibilityLabel = state.inputLabel
        self.inputTextView.accessibilityHint = nil

        self.composerView.accessibilityElements = [
            self.attachButton,
            self.inputTextView,
            self.primaryActionButton
        ]
        self.refreshAccessibilityContainers()
    }

    @objc private func backPressed() {
        self.overlayView.actions.back?()
    }

    @objc private func infoPressed() {
        self.overlayView.actions.openProfile?()
    }

    @objc private func attachPressed() {
        self.overlayView.actions.openAttachments?()
    }

    @objc private func primaryActionPressed() {
        switch self.primaryActionKind {
        case .send:
            self.sendPressed()
        case .record:
            self.recordPressed()
        }
    }

    @objc private func sendPressed() {
        let text = self.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        self.overlayView.actions.sendText?(text)
        self.inputTextView.text = ""
        self.applyComposerState(self.nativeComposerState)
    }

    @objc private func recordPressed() {
        if self.nativeComposerState.isRecording {
            self.overlayView.actions.finishVoiceRecordingAndSend?()
        } else {
            self.overlayView.actions.beginVoiceRecording?()
        }
    }

    func setAccessibilityModalState(_ isModal: Bool) {
        self.view.accessibilityViewIsModal = isModal
        self.view.accessibilityElementsHidden = !isModal
        self.refreshAccessibilityContainers()
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
        if self.inputTextView.isFirstResponder {
            self.extendKeyboardDismissVoiceOverContainment(8.0)
            _ = self.inputTextView.resignFirstResponder()
            let immediateTarget = self.preferredKeyboardDismissFocusTarget()
            UIAccessibility.post(notification: .layoutChanged, argument: immediateTarget)
            self.scheduleKeyboardDismissFocusRestore(after: 0.05, remainingAttempts: 8)
            return true
        }
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
        self.refreshAccessibilityContainers()
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

    func textViewDidChange(_ textView: UITextView) {
        self.applyComposerState(self.nativeComposerState)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        self.keyboardDismissVoiceOverContainmentDeadline = 0.0
        UIAccessibility.post(notification: .layoutChanged, argument: self.inputTextView)
    }

    private func refreshAccessibilityContainers() {
        var rootElements: [Any] = [
            self.backButton,
            self.titleButton,
            self.infoButton,
            self.overlayView.nativeMessageListAccessibilityContainer
        ]
        rootElements.append(contentsOf: self.overlayView.nativeSupplementaryAccessibilityContainers)
        rootElements.append(self.attachButton)
        rootElements.append(self.inputTextView)
        rootElements.append(self.primaryActionButton)
        self.view.accessibilityElements = rootElements
    }

    private func setupKeyboardObservers() {
        let notificationCenter = NotificationCenter.default

        let willChange = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardFrameNotification(notification)
        }
        self.keyboardObservers.append(willChange)

        let willHide = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleKeyboardFrameNotification(notification)
        }
        self.keyboardObservers.append(willHide)
    }

    private func handleKeyboardFrameNotification(_ notification: Notification) {
        let view = self.view
        guard view.window != nil else {
            return
        }
        guard let userInfo = notification.userInfo else {
            return
        }

        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)

        let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let endFrameInView = view.convert(endFrameScreen, from: nil)
        let overlap = max(0.0, view.bounds.maxY - endFrameInView.minY)
        let bottomInset = max(0.0, overlap - view.safeAreaInsets.bottom)

        self.composerBottomConstraint?.constant = -bottomInset
        UIView.animate(withDuration: duration, delay: 0.0, options: [curve, .beginFromCurrentState, .allowUserInteraction]) {
            view.layoutIfNeeded()
        }
    }
}
