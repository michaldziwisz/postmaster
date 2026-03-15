import UIKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ChatPresentationInterfaceState
import ChatHistoryEntry

private final class VoiceOverNativeChatTextView: UITextView {
    var onAccessibilityEscape: (() -> Bool)?

    override func accessibilityPerformEscape() -> Bool {
        if self.onAccessibilityEscape?() == true {
            return true
        }
        return super.accessibilityPerformEscape()
    }
}

private final class VoiceOverNativeChatComposerView: UIView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 65.0)
    }
}

private final class VoiceOverNativeChatMessageCell: UITableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessibilityCustomActions = nil
    }
}

final class VoiceOverNativeChatController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    let overlayView: ChatVoiceOverOverlayView

    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleButton = UIButton(type: .system)
    private let infoButton = UIButton(type: .system)
    private let headerSeparatorView = UIView()
    private let contentView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let composerView = VoiceOverNativeChatComposerView()
    private let composerSeparatorView = UIView()
    private let attachButton = UIButton(type: .system)
    private let inputTextView = VoiceOverNativeChatTextView()
    private let primaryActionButton = UIButton(type: .system)
    private var keyboardObservers: [NSObjectProtocol] = []
    private var accessibilityObservers: [NSObjectProtocol] = []
    private var composerBottomConstraint: NSLayoutConstraint?
    private var lastKnownKeyboardBottomInset: CGFloat = 0.0
    private var observedVisibleKeyboard = false
    private var shouldRestoreFocusAfterKeyboardHide = false
    private var pendingKeyboardFocusRestoreWorkItems: [DispatchWorkItem] = []
    private var keyboardDismissFocusContainmentDeadline: Double = 0.0
    private var primaryActionKind: PrimaryActionKind = .record
    private var interfaceState: ChatPresentationInterfaceState?
    private var didInitialScrollToBottom = false
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

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 88.0
        self.tableView.separatorInset = .zero
        self.tableView.allowsSelection = true
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.alwaysBounceVertical = true
        self.tableView.isAccessibilityElement = false
        if #available(iOS 11.0, *) {
            self.tableView.accessibilityContainerType = .list
        }
        self.contentView.addSubview(self.tableView)

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

            self.tableView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),

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
            self.inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0)
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

        self.overlayView.setNativeComposerHostedExternally(true)
        self.overlayView.setAccessibilityInteractionSuspended(true)
        self.overlayView.accessibilityViewIsModal = false
        self.overlayView.accessibilityElementsHidden = true
        self.overlayView.externalNavigationFocusTargetProvider = nil
        self.overlayView.externalProfileFocusTargetProvider = nil
        self.overlayView.externalNativeKeyboardEscapeHandler = nil
        self.headerView.accessibilityElements = [self.backButton, self.titleButton, self.infoButton]
        self.composerView.accessibilityElements = [self.attachButton, self.inputTextView, self.primaryActionButton]
        self.setupKeyboardObservers()
        self.setupAccessibilityObservers()
    }

    deinit {
        self.overlayView.setNativeComposerHostedExternally(false)
        self.overlayView.setAccessibilityInteractionSuspended(false)
        self.cancelPendingKeyboardFocusRestore()
        let notificationCenter = NotificationCenter.default
        self.keyboardObservers.forEach { notificationCenter.removeObserver($0) }
        self.accessibilityObservers.forEach { notificationCenter.removeObserver($0) }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateTableInsetsForComposer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTableInsetsForComposer()
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

        self.headerView.accessibilityElements = [self.backButton, self.titleButton, self.infoButton]
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

        self.composerView.accessibilityElements = [self.attachButton, self.inputTextView, self.primaryActionButton]
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
        self.applyComposerState(self.currentComposerState())
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
        self.applyModalAccessibilityHierarchy(isModal: isModal)
    }

    override func accessibilityPerformEscape() -> Bool {
        if self.handleVoiceOverKeyboardEscape() {
            return true
        }
        self.backPressed()
        return true
    }

    private func handleVoiceOverKeyboardEscape() -> Bool {
        if self.inputTextView.isFirstResponder {
            self.cancelPendingKeyboardFocusRestore()
            self.shouldRestoreFocusAfterKeyboardHide = true
            self.beginKeyboardDismissFocusContainment()
            _ = self.inputTextView.resignFirstResponder()
            return true
        }
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        self.applyComposerState(self.currentComposerState())
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        UIAccessibility.post(notification: .layoutChanged, argument: self.inputTextView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.lastKnownKeyboardBottomInset > 0.0 || self.observedVisibleKeyboard || self.shouldRestoreFocusAfterKeyboardHide else {
            return
        }

        self.shouldRestoreFocusAfterKeyboardHide = true
        self.beginKeyboardDismissFocusContainment(duration: 2.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else {
                return
            }
            guard UIAccessibility.isVoiceOverRunning else {
                return
            }
            guard self.view.window != nil, !self.view.accessibilityElementsHidden else {
                return
            }
            if self.lastKnownKeyboardBottomInset <= 0.0 {
                self.handleKeyboardDismissedIfNeeded(initialDelay: 0.0)
            }
        }
    }

    private func currentComposerState() -> ChatVoiceOverOverlayView.NativeComposerState {
        return self.overlayView.currentNativeComposerState()
    }

    func updateInterfaceState(_ state: ChatPresentationInterfaceState) {
        self.interfaceState = state

        self.view.backgroundColor = state.theme.list.plainBackgroundColor
        self.contentView.backgroundColor = state.theme.list.plainBackgroundColor
        self.tableView.backgroundColor = state.theme.list.plainBackgroundColor
        self.headerView.backgroundColor = state.theme.rootController.navigationBar.opaqueBackgroundColor
        self.composerView.backgroundColor = state.theme.rootController.navigationBar.opaqueBackgroundColor
        self.headerSeparatorView.backgroundColor = UIColor.separator
        self.composerSeparatorView.backgroundColor = UIColor.separator

        self.backButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.infoButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.titleButton.setTitleColor(state.theme.rootController.navigationBar.primaryTextColor, for: .normal)
        self.attachButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.primaryActionButton.tintColor = state.theme.rootController.navigationBar.accentTextColor

        self.inputTextView.backgroundColor = state.theme.list.itemBlocksBackgroundColor
        self.inputTextView.textColor = state.theme.list.itemPrimaryTextColor
        self.inputTextView.tintColor = state.theme.list.itemAccentColor

        self.applyNavigationState(self.navigationState(for: state))
        self.applyComposerState(self.currentComposerState())
        self.tableView.reloadData()
    }

    func updateEntries(_ entries: [ChatHistoryEntry]) {
        self.tableView.reloadData()

        if !self.didInitialScrollToBottom, self.overlayView.nativeMessageListRowCount() > 0 {
            self.didInitialScrollToBottom = true
            let lastRow = max(0, self.overlayView.nativeMessageListRowCount() - 1)
            let lastIndexPath = IndexPath(row: lastRow, section: 0)
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                guard lastRow < self.tableView.numberOfRows(inSection: 0) else {
                    return
                }
                UIView.performWithoutAnimation {
                    self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: false)
                    self.tableView.layoutIfNeeded()
                }
            }
        }
    }

    func updateLoadEarlierState(canLoadEarlier: Bool, isLoadingEarlier: Bool) {
        self.tableView.reloadData()
    }

    func updateVoicePlaybackState(_ state: ChatVoiceOverOverlayView.VoicePlaybackState?) {
        if let visibleRows = self.tableView.indexPathsForVisibleRows, !visibleRows.isEmpty {
            self.tableView.reloadRows(at: visibleRows, with: .none)
        } else {
            self.tableView.reloadData()
        }
    }

    private func navigationState(for state: ChatPresentationInterfaceState) -> ChatVoiceOverOverlayView.NativeNavigationState {
        let title: String
        if let threadData = state.threadData {
            title = threadData.title
        } else if let forumTopicData = state.forumTopicData {
            title = forumTopicData.title
        } else if let peer = state.renderedPeer?.chatMainPeer {
            if peer.id == state.accountPeerId {
                title = state.strings.DialogList_SavedMessages
            } else {
                title = EnginePeer(peer).displayTitle(strings: state.strings, displayOrder: state.nameDisplayOrder)
            }
        } else {
            title = ""
        }

        return ChatVoiceOverOverlayView.NativeNavigationState(
            title: title,
            backTitle: state.strings.Common_Back,
            infoLabel: state.strings.KeyCommand_ChatInfo,
            infoHint: state.strings.VoiceOver_Chat_OpenHint
        )
    }

    func voiceOverDidReturnToChat(focusInfoButton: Bool = false) {
        let target: Any
        if focusInfoButton {
            target = self.titleButton
        } else if let firstVisible = self.tableView.indexPathsForVisibleRows?.sorted().first,
                  let cell = self.tableView.cellForRow(at: firstVisible) {
            target = cell
        } else {
            target = self.backButton
        }
        UIAccessibility.post(notification: .screenChanged, argument: target)
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: target)
        }
    }

    private func updateTableInsetsForComposer() {
        let composerHeight = self.composerView.bounds.height > 0.0 ? self.composerView.bounds.height : self.composerView.intrinsicContentSize.height
        let bottomInset = max(0.0, composerHeight)
        self.tableView.contentInset.bottom = bottomInset
        if #available(iOS 13.0, *) {
            self.tableView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
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

        let didHide = notificationCenter.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleKeyboardDidHide()
        }
        self.keyboardObservers.append(didHide)
    }

    private func setupAccessibilityObservers() {
        let notificationCenter = NotificationCenter.default
        let focusToken = notificationCenter.addObserver(
            forName: UIAccessibility.elementFocusedNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAccessibilityElementFocused(notification)
        }
        self.accessibilityObservers.append(focusToken)
    }

    private func handleKeyboardFrameNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        let endFrameScreen = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let endFrameInView = self.view.convert(endFrameScreen, from: nil)
        let overlap = max(CGFloat(0.0), self.view.bounds.maxY - endFrameInView.minY)
        let bottomInset = max(CGFloat(0.0), overlap - self.view.safeAreaInsets.bottom)
        let previousBottomInset = self.lastKnownKeyboardBottomInset

        if bottomInset > 0.0 {
            self.observedVisibleKeyboard = true
            self.beginKeyboardDismissFocusContainment()
            self.cancelPendingKeyboardFocusRestore()
            if self.inputTextView.isFirstResponder {
                self.shouldRestoreFocusAfterKeyboardHide = false
            }
        }

        guard bottomInset != self.lastKnownKeyboardBottomInset else {
            return
        }
        self.lastKnownKeyboardBottomInset = bottomInset
        self.composerBottomConstraint?.constant = -bottomInset
        UIView.animate(withDuration: duration, delay: 0.0, options: [curve, .beginFromCurrentState, .allowUserInteraction]) {
            self.view.layoutIfNeeded()
        }

        if previousBottomInset > 0.0, bottomInset <= 0.0 {
            self.handleKeyboardDismissedIfNeeded(initialDelay: max(0.05, duration + 0.05))
        }
    }

    private func handleKeyboardDidHide() {
        self.handleKeyboardDismissedIfNeeded(initialDelay: 0.0)
    }

    private func handleAccessibilityElementFocused(_ notification: Notification) {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.lastKnownKeyboardBottomInset <= 0.0 else {
            return
        }
        guard CACurrentMediaTime() < self.keyboardDismissFocusContainmentDeadline else {
            return
        }
        guard let userInfo = notification.userInfo else {
            return
        }
        let focusedElement = userInfo[UIAccessibility.focusedElementUserInfoKey]
        if self.isVoiceOverElementWithinNativeChat(focusedElement) {
            return
        }
        self.forceFocusBackIntoNativeChat()
    }

    private func handleKeyboardDismissedIfNeeded(initialDelay: TimeInterval) {
        guard self.shouldRestoreFocusAfterKeyboardHide || self.observedVisibleKeyboard else {
            return
        }
        self.shouldRestoreFocusAfterKeyboardHide = false
        self.observedVisibleKeyboard = false
        self.beginKeyboardDismissFocusContainment(duration: max(1.5, initialDelay + 1.0))
        self.scheduleKeyboardFocusRestore(initialDelay: initialDelay)
    }

    private func scheduleKeyboardFocusRestore(initialDelay: TimeInterval = 0.0) {
        self.cancelPendingKeyboardFocusRestore()
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.view.window != nil, !self.view.accessibilityElementsHidden else {
            return
        }
        for delay in [initialDelay, initialDelay + 0.25, initialDelay + 0.8] {
            let workItem = DispatchWorkItem { [weak self] in
                guard let self else {
                    return
                }
                guard UIAccessibility.isVoiceOverRunning else {
                    return
                }
                guard self.view.window != nil, !self.view.accessibilityElementsHidden else {
                    return
                }
                self.restoreVoiceOverFocusAfterKeyboardDismissIfNeeded()
            }
            self.pendingKeyboardFocusRestoreWorkItems.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    private func beginKeyboardDismissFocusContainment(duration: Double = 1.5) {
        self.keyboardDismissFocusContainmentDeadline = max(self.keyboardDismissFocusContainmentDeadline, CACurrentMediaTime() + duration)
    }

    private func forceFocusBackIntoNativeChat() {
        self.cancelPendingKeyboardFocusRestore()
        self.beginKeyboardDismissFocusContainment()
        self.restoreVoiceOverFocusAfterKeyboardDismissIfNeeded()
        self.scheduleKeyboardFocusRestore()
    }

    private func cancelPendingKeyboardFocusRestore() {
        self.pendingKeyboardFocusRestoreWorkItems.forEach { $0.cancel() }
        self.pendingKeyboardFocusRestoreWorkItems.removeAll()
    }

    private func applyModalAccessibilityHierarchy(isModal: Bool) {
        if let parentView = self.parent?.view {
            parentView.isAccessibilityElement = false
            parentView.accessibilityViewIsModal = isModal
            if isModal, self.view.isDescendant(of: parentView) {
                parentView.shouldGroupAccessibilityChildren = true
                parentView.accessibilityElements = [self.view as Any]
            } else {
                parentView.shouldGroupAccessibilityChildren = false
                parentView.accessibilityElements = nil
            }
        }

        if let navigationView = self.navigationController?.view {
            navigationView.isAccessibilityElement = false
            navigationView.accessibilityViewIsModal = isModal
            if isModal {
                let hierarchyRoot: Any
                if let parentView = self.parent?.view, parentView.isDescendant(of: navigationView) {
                    hierarchyRoot = parentView as Any
                } else {
                    hierarchyRoot = self.view as Any
                }
                navigationView.shouldGroupAccessibilityChildren = true
                navigationView.accessibilityElements = [hierarchyRoot]
            } else {
                navigationView.shouldGroupAccessibilityChildren = false
                navigationView.accessibilityElements = nil
            }
        }
    }

    private func enforceNativeChatModalIsolation() {
        self.setAccessibilityModalState(true)
    }

    private func restoreVoiceOverFocusAfterKeyboardDismissIfNeeded() {
        self.enforceNativeChatModalIsolation()
        let target = self.preferredPostKeyboardFocusTarget()
        guard self.shouldRestoreVoiceOverFocus(to: target) else {
            return
        }
        UIAccessibility.post(notification: .screenChanged, argument: target)
        DispatchQueue.main.async {
            UIAccessibility.post(notification: .layoutChanged, argument: target)
        }
    }

    private func preferredPostKeyboardFocusTarget() -> Any {
        if let composerTarget = self.preferredComposerFocusTarget() {
            return composerTarget
        } else if let messageTarget = self.preferredVisibleMessageFocusTarget() {
            return messageTarget
        } else if self.tableView.window != nil, !self.tableView.isHidden, self.tableView.alpha > 0.01 {
            return self.tableView
        } else if self.backButton.window != nil, !self.backButton.isHidden, self.backButton.alpha > 0.01 {
            return self.backButton
        } else if self.titleButton.window != nil, !self.titleButton.isHidden, self.titleButton.alpha > 0.01 {
            return self.titleButton
        } else if self.infoButton.window != nil, !self.infoButton.isHidden, self.infoButton.alpha > 0.01 {
            return self.infoButton
        } else {
            return self.view as Any
        }
    }

    private func shouldRestoreVoiceOverFocus(to target: Any) -> Bool {
        let focusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver)
        guard let focusedElement else {
            return true
        }
        if self.isSameVoiceOverElement(focusedElement, target) {
            return false
        }
        if let focusedView = focusedElement as? UIView {
            if focusedView === self.inputTextView || focusedView.isDescendant(of: self.inputTextView) {
                return true
            }
            return focusedView === self.view || !focusedView.isDescendant(of: self.view)
        }
        if let accessibilityElement = focusedElement as? UIAccessibilityElement,
           let containerView = accessibilityElement.accessibilityContainer as? UIView {
            if containerView === self.inputTextView || containerView.isDescendant(of: self.inputTextView) {
                return true
            }
            return containerView === self.view || !containerView.isDescendant(of: self.view)
        }
        return true
    }

    private func isSameVoiceOverElement(_ lhs: Any, _ rhs: Any) -> Bool {
        return (lhs as AnyObject) === (rhs as AnyObject)
    }

    private func preferredComposerFocusTarget() -> Any? {
        guard self.composerView.window != nil, !self.composerView.isHidden, self.composerView.alpha > 0.01 else {
            return nil
        }
        if self.primaryActionButton.isAccessibilityElement, !self.primaryActionButton.isHidden, self.primaryActionButton.alpha > 0.01, self.primaryActionButton.isEnabled {
            return self.primaryActionButton
        }
        if self.attachButton.isAccessibilityElement, !self.attachButton.isHidden, self.attachButton.alpha > 0.01, self.attachButton.isEnabled {
            return self.attachButton
        }
        if !self.inputTextView.isHidden, self.inputTextView.alpha > 0.01, self.inputTextView.isUserInteractionEnabled {
            return self.inputTextView
        }
        return nil
    }

    private func preferredVisibleMessageFocusTarget() -> Any? {
        let rowCount = max(0, self.tableView.numberOfRows(inSection: 0))
        guard rowCount > 0 else {
            return nil
        }

        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.sorted(), !visibleIndexPaths.isEmpty else {
            return self.tableView
        }

        let targetIndexPath: IndexPath
        if self.isNearBottom() {
            targetIndexPath = visibleIndexPaths.last ?? IndexPath(row: max(0, rowCount - 1), section: 0)
        } else if self.isNearTop() {
            targetIndexPath = visibleIndexPaths.first ?? IndexPath(row: 0, section: 0)
        } else {
            let visibleMidY = self.tableView.contentOffset.y + self.tableView.bounds.height * 0.5
            var bestIndexPath = visibleIndexPaths[0]
            var bestDistance = abs(self.tableView.rectForRow(at: bestIndexPath).midY - visibleMidY)
            for indexPath in visibleIndexPaths.dropFirst() {
                let distance = abs(self.tableView.rectForRow(at: indexPath).midY - visibleMidY)
                if distance < bestDistance {
                    bestDistance = distance
                    bestIndexPath = indexPath
                }
            }
            targetIndexPath = bestIndexPath
        }

        return self.tableView.cellForRow(at: targetIndexPath) ?? self.tableView
    }

    private func isNearBottom() -> Bool {
        let visibleHeight = self.tableView.bounds.height
        if visibleHeight <= 0.0 {
            return true
        }
        let contentHeight = self.tableView.contentSize.height
        let y = self.tableView.contentOffset.y
        let threshold: CGFloat = 180.0
        return y + visibleHeight + threshold >= contentHeight
    }

    private func isNearTop() -> Bool {
        let minOffset = -self.tableView.adjustedContentInset.top
        let threshold: CGFloat = 120.0
        return self.tableView.contentOffset.y - minOffset <= threshold
    }

    private func isVoiceOverElementWithinNativeChat(_ focusedElement: Any?) -> Bool {
        if let focusedView = focusedElement as? UIView {
            return focusedView === self.view || focusedView.isDescendant(of: self.view)
        }
        if let accessibilityElement = focusedElement as? UIAccessibilityElement,
           let containerView = accessibilityElement.accessibilityContainer as? UIView {
            return containerView === self.view || containerView.isDescendant(of: self.view)
        }
        return false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.overlayView.nativeMessageListRowCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: VoiceOverNativeChatMessageCell
        if let current = tableView.dequeueReusableCell(withIdentifier: "Message") as? VoiceOverNativeChatMessageCell {
            cell = current
        } else {
            cell = VoiceOverNativeChatMessageCell(style: .subtitle, reuseIdentifier: "Message")
        }
        guard let presentation = self.overlayView.nativeMessageListPresentation(at: indexPath, menuRectProvider: { [weak self, weak cell] in
            guard let self, let cell else {
                return nil
            }
            return self.view.convert(cell.bounds, from: cell)
        }) else {
            return cell
        }

        cell.textLabel?.text = presentation.title
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: presentation.usesProminentStyle ? .headline : .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.textAlignment = presentation.usesProminentStyle ? .center : .natural

        cell.detailTextLabel?.text = presentation.subtitle
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.textAlignment = presentation.usesProminentStyle ? .center : .natural

        if presentation.usesProminentStyle {
            cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20.0, leading: 24.0, bottom: 20.0, trailing: 24.0)
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: 24.0, bottom: 0.0, right: 24.0)
        } else {
            cell.contentView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12.0, leading: 16.0, bottom: 12.0, trailing: 16.0)
            cell.separatorInset = .zero
        }

        if let state = self.interfaceState {
            cell.backgroundColor = state.theme.list.plainBackgroundColor
            let primaryColor = presentation.usesAccentColor ? state.theme.list.itemAccentColor : state.theme.list.itemPrimaryTextColor
            cell.textLabel?.textColor = primaryColor
            cell.detailTextLabel?.textColor = state.theme.list.itemSecondaryTextColor
        }

        cell.selectionStyle = presentation.selectionStyle
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = presentation.accessibilityLabel
        cell.accessibilityHint = presentation.accessibilityHint
        cell.accessibilityTraits = presentation.accessibilityTraits
        cell.accessibilityCustomActions = presentation.accessibilityCustomActions
        return cell
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.overlayView.nativeMessageListEstimatedHeight(at: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.overlayView.nativeMessageListEstimatedHeight(at: indexPath) == 96.0 && indexPath.row == 0 {
            return 96.0
        }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let presentation = self.overlayView.nativeMessageListPresentation(at: indexPath, menuRectProvider: { nil }) else {
            return nil
        }
        return presentation.selectionStyle == .none ? nil : indexPath
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        _ = self.overlayView.activateNativeMessageListRow(at: indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.overlayView.nativeMessageListDidScroll(visibleIndexPaths: self.tableView.indexPathsForVisibleRows ?? [])
    }
}
