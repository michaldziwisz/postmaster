import Foundation
import UIKit
import AppBundle
import Postbox
import TelegramCore
import TelegramPresentationData
import ChatPresentationInterfaceState
import TelegramStringFormatting
import ChatHistoryEntry
import TelegramUIPreferences

private final class ChatVoiceOverOverlayTableView: UITableView {
    var onAccessibilityScrollBoundary: ((UIAccessibilityScrollDirection) -> Bool)?
    
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        if super.accessibilityScroll(direction) {
            return true
        }
        
        let normalizedDirection: UIAccessibilityScrollDirection
        switch direction {
        case .next:
            normalizedDirection = .down
        case .previous:
            normalizedDirection = .up
        default:
            normalizedDirection = direction
        }

        if normalizedDirection != direction, super.accessibilityScroll(normalizedDirection) {
            return true
        }
        if self.performManualAccessibilityScrollIfPossible(direction: normalizedDirection) {
            return true
        }
        if let onAccessibilityScrollBoundary, onAccessibilityScrollBoundary(normalizedDirection) {
            return true
        }
        return false
    }
    
    private func performManualAccessibilityScrollIfPossible(direction: UIAccessibilityScrollDirection) -> Bool {
        let minOffset = -self.adjustedContentInset.top
        let maxOffset = max(minOffset, self.contentSize.height - self.bounds.height + self.adjustedContentInset.bottom)
        
        let currentOffset = self.contentOffset.y
        let pageHeight = max(1.0, self.bounds.height - self.adjustedContentInset.top - self.adjustedContentInset.bottom)
        let delta = pageHeight * 0.85
        
        let targetOffset: CGFloat
        switch direction {
        case .up:
            targetOffset = max(minOffset, currentOffset - delta)
        case .down:
            targetOffset = min(maxOffset, currentOffset + delta)
        default:
            return false
        }
        
        if abs(targetOffset - currentOffset) < 1.0 {
            return false
        }
        
        self.setContentOffset(CGPoint(x: self.contentOffset.x, y: targetOffset), animated: false)
        UIAccessibility.post(notification: .pageScrolled, argument: nil)
        return true
    }
}

private final class ChatVoiceOverOverlayCell: UITableViewCell {
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var current: UIView? = self
        while let view = current {
            if let tableView = view as? UITableView {
                return tableView.accessibilityScroll(direction)
            }
            current = view.superview
        }
        return super.accessibilityScroll(direction)
    }
}

public final class ChatVoiceOverOverlayView: UIView {
    public struct Actions {
        public var back: (() -> Void)?
        public var openProfile: (() -> Void)?
        public var openAttachments: (() -> Void)?
        public var sendText: ((String) -> Void)?
        public var beginVoiceRecording: (() -> Void)?
        public var finishVoiceRecordingAndSend: (() -> Void)?
        public var requestLoadEarlier: (() -> Void)?
        public var didEndLoadEarlier: (() -> Void)?
        public var scrollToLatest: (() -> Void)?
        public var activateMessage: ((Message) -> Void)?
        public var openMessageContextMenu: ((Message, CGRect) -> Void)?
        
        public init(
            back: (() -> Void)? = nil,
            openProfile: (() -> Void)? = nil,
            openAttachments: (() -> Void)? = nil,
            sendText: ((String) -> Void)? = nil,
            beginVoiceRecording: (() -> Void)? = nil,
            finishVoiceRecordingAndSend: (() -> Void)? = nil,
            requestLoadEarlier: (() -> Void)? = nil,
            didEndLoadEarlier: (() -> Void)? = nil,
            scrollToLatest: (() -> Void)? = nil,
            activateMessage: ((Message) -> Void)? = nil,
            openMessageContextMenu: ((Message, CGRect) -> Void)? = nil
        ) {
            self.back = back
            self.openProfile = openProfile
            self.openAttachments = openAttachments
            self.sendText = sendText
            self.beginVoiceRecording = beginVoiceRecording
            self.finishVoiceRecordingAndSend = finishVoiceRecordingAndSend
            self.requestLoadEarlier = requestLoadEarlier
            self.didEndLoadEarlier = didEndLoadEarlier
            self.scrollToLatest = scrollToLatest
            self.activateMessage = activateMessage
            self.openMessageContextMenu = openMessageContextMenu
        }
    }
    
    private struct Row {
        enum Kind {
            case message(Message)
            case info(String)
        }
        
        var stableId: UInt64
        var index: MessageIndex
        var kind: Kind
    }
    
    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let profileButton = UIButton(type: .system)
    
    private let tableView = ChatVoiceOverOverlayTableView(frame: .zero, style: .plain)
    private let refreshControl = UIRefreshControl()
    
    private let composerView = UIView()
    private let attachButton = UIButton(type: .system)
    private let inputTextView = UITextView()
    private let recordButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    
    private var composerBottomConstraint: NSLayoutConstraint?
    private var keyboardObservers: [NSObjectProtocol] = []
    
    private var interfaceState: ChatPresentationInterfaceState?
    private var rows: [Row] = []

    private var canLoadEarlierHistory = false
    private var isLoadingEarlierHistory = false
    private var didReceiveLoadEarlierState = false
    
    private var shouldShowLoadEarlierRow: Bool {
        return self.didReceiveLoadEarlierState || self.canLoadEarlierHistory || self.isLoadEarlierInProgress
    }
    
    private var isLoadEarlierInProgress: Bool {
        return self.isWaitingForLoadEarlier
    }
    
    private var loadEarlierRowOffset: Int {
        return self.shouldShowLoadEarlierRow ? 1 : 0
    }
    
    private var didInitialScrollToBottom = false
    private var pendingEntries: [ChatHistoryEntry]?
    private var pendingEntriesWorkItem: DispatchWorkItem?
    private var isWaitingForLoadEarlier = false
    private var lastLoadEarlierRequestTimestamp: CFTimeInterval = 0.0
    private var loadEarlierRequestId: Int = 0
    private var loadEarlierNoProgressCount: Int = 0
    private var forceScrollToBottomOnNextApply = false
    private var loadEarlierOldestIndexBeforeRequest: MessageIndex?

    private struct ScrollAnchor: Equatable {
        var stableId: UInt64
        var messageId: MessageId?
        var offset: CGFloat
    }
    private var loadEarlierScrollAnchor: ScrollAnchor?

    private var isComposerEnabled: Bool = true
    
    public var actions = Actions()
    
    private static let maxLoadEarlierNoProgressCount: Int = 200
    private static let loadEarlierTimeout: TimeInterval = 12.0
    
    private static let voiceMessageDurationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.allowedUnits = [.minute, .second]
        return formatter
    }()
    
    private static let fileSizeFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowsNonnumericFormatting = true
        return formatter
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isAccessibilityElement = false
        self.accessibilityViewIsModal = true
        
        self.topBarView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.topBarView)
        
        self.backButton.translatesAutoresizingMaskIntoConstraints = false
        self.backButton.addTarget(self, action: #selector(self.backPressed), for: .touchUpInside)
        self.topBarView.addSubview(self.backButton)
        
        self.profileButton.translatesAutoresizingMaskIntoConstraints = false
        self.profileButton.addTarget(self, action: #selector(self.profilePressed), for: .touchUpInside)
        self.topBarView.addSubview(self.profileButton)
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.numberOfLines = 2
        self.titleLabel.textAlignment = .center
        self.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.isAccessibilityElement = true
        self.titleLabel.accessibilityTraits = [.header]
        self.topBarView.addSubview(self.titleLabel)
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 96.0
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.alwaysBounceVertical = true
        self.refreshControl.addTarget(self, action: #selector(self.refreshTriggered), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        self.addSubview(self.tableView)
        
        self.composerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.composerView)
        
        self.attachButton.translatesAutoresizingMaskIntoConstraints = false
        self.attachButton.addTarget(self, action: #selector(self.attachPressed), for: .touchUpInside)
        self.composerView.addSubview(self.attachButton)
        
        self.inputTextView.translatesAutoresizingMaskIntoConstraints = false
        self.inputTextView.delegate = self
        self.inputTextView.font = UIFont.preferredFont(forTextStyle: .body)
        self.inputTextView.adjustsFontForContentSizeCategory = true
        self.inputTextView.layer.cornerRadius = 10.0
        self.inputTextView.layer.masksToBounds = true
        self.inputTextView.textContainerInset = UIEdgeInsets(top: 8.0, left: 6.0, bottom: 8.0, right: 6.0)
        self.composerView.addSubview(self.inputTextView)
        
        self.recordButton.translatesAutoresizingMaskIntoConstraints = false
        self.recordButton.addTarget(self, action: #selector(self.recordPressed), for: .touchUpInside)
        self.composerView.addSubview(self.recordButton)
        
        self.sendButton.translatesAutoresizingMaskIntoConstraints = false
        self.sendButton.addTarget(self, action: #selector(self.sendPressed), for: .touchUpInside)
        self.composerView.addSubview(self.sendButton)
        
        let composerBottom = self.composerView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor)
        self.composerBottomConstraint = composerBottom
        
        NSLayoutConstraint.activate([
            self.topBarView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            self.topBarView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.topBarView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            
            self.backButton.leadingAnchor.constraint(equalTo: self.topBarView.leadingAnchor, constant: 12.0),
            self.backButton.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            
            self.profileButton.trailingAnchor.constraint(equalTo: self.topBarView.trailingAnchor, constant: -12.0),
            self.profileButton.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),
            
            self.titleLabel.topAnchor.constraint(equalTo: self.topBarView.topAnchor, constant: 10.0),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.topBarView.bottomAnchor, constant: -10.0),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.backButton.trailingAnchor, constant: 12.0),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.profileButton.leadingAnchor, constant: -12.0),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.topBarView.centerXAnchor),
            
            self.composerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.composerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            composerBottom,
            
            self.attachButton.leadingAnchor.constraint(equalTo: self.composerView.leadingAnchor, constant: 12.0),
            self.attachButton.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.attachButton.widthAnchor.constraint(equalToConstant: 44.0),
            self.attachButton.heightAnchor.constraint(equalToConstant: 44.0),
            
            self.sendButton.trailingAnchor.constraint(equalTo: self.composerView.trailingAnchor, constant: -12.0),
            self.sendButton.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.sendButton.widthAnchor.constraint(equalToConstant: 44.0),
            self.sendButton.heightAnchor.constraint(equalToConstant: 44.0),
            
            self.recordButton.trailingAnchor.constraint(equalTo: self.sendButton.leadingAnchor, constant: -8.0),
            self.recordButton.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.recordButton.widthAnchor.constraint(equalToConstant: 44.0),
            self.recordButton.heightAnchor.constraint(equalToConstant: 44.0),
            
            self.inputTextView.leadingAnchor.constraint(equalTo: self.attachButton.trailingAnchor, constant: 8.0),
            self.inputTextView.trailingAnchor.constraint(equalTo: self.recordButton.leadingAnchor, constant: -8.0),
            self.inputTextView.topAnchor.constraint(equalTo: self.composerView.topAnchor, constant: 10.0),
            self.inputTextView.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),
            
            self.tableView.topAnchor.constraint(equalTo: self.topBarView.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.composerView.topAnchor)
        ])

        self.setupKeyboardObservers()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        let nc = NotificationCenter.default
        for token in self.keyboardObservers {
            nc.removeObserver(token)
        }
    }
    
    func updateInterfaceState(_ state: ChatPresentationInterfaceState) {
        self.interfaceState = state
        if state.renderedPeer?.peer != nil {
            self.isComposerEnabled = canSendMessagesToChat(state)
        } else {
            self.isComposerEnabled = true
        }
        
        self.backgroundColor = state.theme.list.plainBackgroundColor
        self.topBarView.backgroundColor = state.theme.rootController.navigationBar.opaqueBackgroundColor
        self.composerView.backgroundColor = state.theme.chat.inputPanel.panelBackgroundColor
        self.tableView.backgroundColor = state.theme.list.plainBackgroundColor
        
        self.inputTextView.backgroundColor = state.theme.list.itemBlocksBackgroundColor
        self.inputTextView.textColor = state.theme.list.itemPrimaryTextColor
        self.inputTextView.tintColor = state.theme.list.itemAccentColor
        
        self.titleLabel.textColor = state.theme.rootController.navigationBar.primaryTextColor
        self.backButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.profileButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.attachButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.recordButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        self.sendButton.tintColor = state.theme.rootController.navigationBar.accentTextColor
        
        self.backButton.setTitle(state.strings.Common_Back, for: .normal)
        self.backButton.accessibilityLabel = state.strings.Common_Back
        
        self.profileButton.setTitle("ⓘ", for: .normal)
        self.profileButton.accessibilityLabel = state.strings.KeyCommand_ChatInfo
        self.profileButton.accessibilityHint = state.strings.VoiceOver_Chat_OpenHint
        self.profileButton.accessibilityTraits = [.button]
        
        self.attachButton.setTitle("＋", for: .normal)
        self.attachButton.accessibilityLabel = state.strings.VoiceOver_AttachMedia
        self.attachButton.accessibilityTraits = [.button]
        
        self.sendButton.setTitle("➤", for: .normal)
        self.sendButton.accessibilityLabel = state.strings.MediaPicker_Send
        self.sendButton.accessibilityTraits = [.button]

        let isComposerEnabled = self.isComposerEnabled
        self.composerView.isUserInteractionEnabled = isComposerEnabled
        self.composerView.accessibilityElementsHidden = !isComposerEnabled

        self.attachButton.isEnabled = isComposerEnabled
        self.sendButton.isEnabled = isComposerEnabled
        self.inputTextView.isEditable = isComposerEnabled
        self.inputTextView.isSelectable = isComposerEnabled
        self.inputTextView.isUserInteractionEnabled = isComposerEnabled
        if !isComposerEnabled, self.inputTextView.isFirstResponder {
            self.inputTextView.resignFirstResponder()
        }
        
        self.inputTextView.accessibilityLabel = state.strings.Conversation_InputTextPlaceholder
        self.inputTextView.accessibilityHint = nil
        
        self.updateRecordButton(state: state)
        self.updateTitle(state: state)
    }
    
    func updateEntries(_ entries: [ChatHistoryEntry]) {
        self.pendingEntries = entries
        self.schedulePendingEntriesApplyIfNeeded()
    }
    
    public func updateLoadEarlierState(canLoadEarlier: Bool, isLoadingEarlier: Bool) {
        let didReceiveChange = !self.didReceiveLoadEarlierState
        if didReceiveChange {
            self.didReceiveLoadEarlierState = true
        }
        
        let didChange = didReceiveChange || (self.canLoadEarlierHistory != canLoadEarlier) || (self.isLoadingEarlierHistory != isLoadingEarlier)
        self.canLoadEarlierHistory = canLoadEarlier
        self.isLoadingEarlierHistory = isLoadingEarlier

        guard didChange else {
            return
        }
        
        UIView.performWithoutAnimation {
            if !didReceiveChange, self.shouldShowLoadEarlierRow, self.tableView.numberOfRows(inSection: 0) > 0 {
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            } else {
                self.tableView.reloadData()
            }
            self.tableView.layoutIfNeeded()
        }
    }

    private func schedulePendingEntriesApplyIfNeeded() {
        guard self.pendingEntries != nil else {
            return
        }
        guard self.pendingEntriesWorkItem == nil else {
            return
        }
        
        let delay: TimeInterval = (self.tableView.isDragging || self.tableView.isDecelerating) ? 0.2 : 0.05
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            self.pendingEntriesWorkItem = nil
            
            if self.tableView.isDragging || self.tableView.isDecelerating {
                self.schedulePendingEntriesApplyIfNeeded()
                return
            }
            self.applyPendingEntriesIfPossible()
            self.schedulePendingEntriesApplyIfNeeded()
        }
        self.pendingEntriesWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func updateTitle(state: ChatPresentationInterfaceState) {
        var title: String?
        
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
        }
        
        self.titleLabel.text = title ?? ""
        self.titleLabel.accessibilityLabel = title ?? ""
    }
    
    private func updateRecordButton(state: ChatPresentationInterfaceState) {
        guard self.isComposerEnabled else {
            self.recordButton.setTitle("●", for: .normal)
            self.recordButton.accessibilityLabel = state.strings.VoiceOver_Chat_RecordModeVoiceMessage
            self.recordButton.accessibilityHint = nil
            self.recordButton.isEnabled = false
            self.recordButton.accessibilityTraits = [.button, .notEnabled]
            return
        }

        let isRecording = state.inputTextPanelState.mediaRecordingState != nil
        
        if isRecording {
            self.recordButton.setTitle("■", for: .normal)
            self.recordButton.accessibilityLabel = state.strings.VoiceOver_Camera_StopVideoRecording
            self.recordButton.accessibilityHint = nil
            self.recordButton.accessibilityTraits = [.button]
        } else {
            self.recordButton.setTitle("●", for: .normal)
            self.recordButton.accessibilityLabel = state.strings.VoiceOver_Chat_RecordModeVoiceMessage
            self.recordButton.accessibilityHint = state.strings.VoiceOver_Chat_RecordModeVoiceMessageInfo
            self.recordButton.accessibilityTraits = [.button]
            
            if !state.voiceMessagesAvailable {
                self.recordButton.isEnabled = false
                self.recordButton.accessibilityTraits.insert(.notEnabled)
            } else {
                self.recordButton.isEnabled = true
            }
        }
    }
    
    private func makeRows(from entries: [ChatHistoryEntry]) -> [Row] {
        var result: [Row] = []
        
        let sortedEntries = entries.sorted(by: { $0.index < $1.index })
        for entry in sortedEntries {
            switch entry {
            case let .MessageEntry(message, _, _, _, _, _):
                result.append(Row(stableId: entry.stableId, index: message.index, kind: .message(message)))
            case let .MessageGroupEntry(_, messages, _):
                if let message = messages.last?.0 {
                    result.append(Row(stableId: entry.stableId, index: message.index, kind: .message(message)))
                }
            case .UnreadEntry:
                break
            case let .ChatInfoEntry(info, _):
                switch info {
                case let .botInfo(title, text, _, _):
                    let combined = "\(title)\n\(text)"
                    result.append(Row(stableId: entry.stableId, index: entry.index, kind: .info(combined)))
                case let .userInfo(peer, _, _, _, _):
                    result.append(Row(stableId: entry.stableId, index: entry.index, kind: .info(peer.displayTitle(strings: self.interfaceState?.strings ?? defaultPresentationStrings, displayOrder: PresentationPersonNameOrder.firstLast))))
                case .newThreadInfo:
                    break
                }
            case .ReplyCountEntry:
                break
            }
        }
        
        return result
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count + self.loadEarlierRowOffset
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let current = tableView.dequeueReusableCell(withIdentifier: "Cell") as? ChatVoiceOverOverlayCell {
            cell = current
        } else {
            cell = ChatVoiceOverOverlayCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        
        cell.selectionStyle = .none
        cell.isAccessibilityElement = true
        cell.accessibilityCustomActions = nil

        if self.shouldShowLoadEarlierRow, indexPath.row == 0 {
            let bundle = getAppBundle()
            
            let title: String
            let traits: UIAccessibilityTraits
            if self.isLoadEarlierInProgress {
                let titleKey = "VoiceOver.Chat.LoadEarlier.Loading"
                let titleFallback = "Loading older messages"
                title = bundle.localizedString(forKey: titleKey, value: titleFallback, table: nil)
                traits = [.button, .notEnabled]
                cell.selectionStyle = .none
            } else if self.canLoadEarlierHistory {
                let titleKey = "VoiceOver.Chat.LoadEarlier"
                let titleFallback = "Load older messages"
                title = bundle.localizedString(forKey: titleKey, value: titleFallback, table: nil)
                traits = [.button]
                cell.selectionStyle = .default
            } else {
                let titleKey = "VoiceOver.Chat.LoadEarlier.None"
                let titleFallback = "No older messages"
                title = bundle.localizedString(forKey: titleKey, value: titleFallback, table: nil)
                traits = [.staticText]
                cell.selectionStyle = .none
            }

            cell.textLabel?.text = title
            cell.detailTextLabel?.text = nil
            
            if let state = self.interfaceState {
                cell.backgroundColor = state.theme.list.plainBackgroundColor
                cell.textLabel?.textColor = (traits.contains(.button) ? state.theme.list.itemAccentColor : state.theme.list.itemSecondaryTextColor)
            }
            
            cell.accessibilityLabel = title
            cell.accessibilityHint = nil
            cell.accessibilityTraits = traits

            #if DEBUG
            let debugTitle = "Speak debug state"
            cell.accessibilityCustomActions = [
                UIAccessibilityCustomAction(name: debugTitle, actionHandler: { [weak self] _ in
                    guard let self else {
                        return false
                    }
                    let now = CACurrentMediaTime()
                    let lastRequestAgeMs = Int((now - self.lastLoadEarlierRequestTimestamp) * 1000.0)
                    let beforeOldestId = self.loadEarlierOldestIndexBeforeRequest?.id.id
                    let currentOldestId = self.rows.first?.index.id.id
                    let message = "Load earlier debug. waiting \(self.isWaitingForLoadEarlier ? "true" : "false"). canLoadEarlier \(self.canLoadEarlierHistory ? "true" : "false"). isLoadingEarlier \(self.isLoadingEarlierHistory ? "true" : "false"). rows \(self.rows.count). beforeOldestId \(String(describing: beforeOldestId)). currentOldestId \(String(describing: currentOldestId)). requestId \(self.loadEarlierRequestId). noProgressCount \(self.loadEarlierNoProgressCount). lastRequestAge \(lastRequestAgeMs) ms."
                    UIAccessibility.post(notification: .announcement, argument: message)
                    return true
                })
            ]
            #endif
            
            return cell
        }
        
        let rowIndex = indexPath.row - self.loadEarlierRowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = ""
            cell.accessibilityTraits = [.staticText]
            return cell
        }
        
        guard let state = self.interfaceState else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = ""
            cell.accessibilityTraits = [.staticText]
            return cell
        }
        
        let row = self.rows[rowIndex]
        let resolved = self.resolveRow(row, state: state)
        
        cell.textLabel?.text = resolved.title
        cell.textLabel?.textColor = state.theme.list.itemPrimaryTextColor
        cell.detailTextLabel?.text = resolved.subtitle
        cell.detailTextLabel?.textColor = state.theme.list.itemSecondaryTextColor
        
        cell.accessibilityLabel = resolved.accessibilityLabel
        cell.accessibilityHint = resolved.hint
        var traits = resolved.traits
        if case .message = row.kind {
            traits.remove(.button)
        }
        cell.accessibilityTraits = traits

        if case let .message(message) = row.kind, self.isMessageActivatable(message) {
            cell.selectionStyle = .default
        }

        if case let .message(message) = row.kind {
            var customActions: [UIAccessibilityCustomAction] = []
            
            let moreTitle = state.strings.Conversation_ContextMenuMore
            customActions.append(UIAccessibilityCustomAction(name: moreTitle, actionHandler: { [weak self] _ in
                guard let self else {
                    return false
                }
                let rect = self.tableView.convert(self.tableView.rectForRow(at: indexPath), to: self)
                self.actions.openMessageContextMenu?(message, rect)
                return true
            }))
            
            let messageText = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !messageText.isEmpty {
                let copyTitle = state.strings.Conversation_ContextMenuCopy
                customActions.append(UIAccessibilityCustomAction(name: copyTitle, actionHandler: { _ in
                    UIPasteboard.general.string = messageText
                    if UIAccessibility.isVoiceOverRunning {
                        UIAccessibility.post(notification: .announcement, argument: state.strings.Conversation_TextCopied)
                    }
                    return true
                }))
            }
            
            cell.accessibilityCustomActions = customActions
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if self.shouldShowLoadEarlierRow, indexPath.row == 0 {
            guard self.canLoadEarlierHistory, !self.isLoadEarlierInProgress else {
                return nil
            }
            return indexPath
        }
        
        let rowIndex = indexPath.row - self.loadEarlierRowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            return nil
        }
        let row = self.rows[rowIndex]
        switch row.kind {
        case let .message(message):
            return self.isMessageActivatable(message) ? indexPath : nil
        case .info:
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.shouldShowLoadEarlierRow, indexPath.row == 0 {
            self.triggerLoadEarlierRequest()
            return
        }
        
        let rowIndex = indexPath.row - self.loadEarlierRowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            return
        }
        let row = self.rows[rowIndex]
        if case let .message(message) = row.kind {
            self.actions.activateMessage?(message)
        }
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.shouldShowLoadEarlierRow, indexPath.row == 0 {
            return 64.0
        }
        
        let rowIndex = indexPath.row - self.loadEarlierRowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            return tableView.estimatedRowHeight
        }
        
        let row = self.rows[rowIndex]
        switch row.kind {
        case let .info(text):
            let lines = max(1, min(6, (text.count / 44) + 1))
            return max(72.0, CGFloat(24 * lines + 28))
        case let .message(message):
            if !message.text.isEmpty {
                let lines = max(1, min(8, (message.text.count / 36) + 1))
                return max(72.0, CGFloat(26 + (lines * 22)))
            } else {
                return 88.0
            }
        }
    }
    
    public func scrollViewDidScroll(_ _: UIScrollView) {
        if !self.isNearTop() {
            self.loadEarlierNoProgressCount = 0
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === self.tableView else {
            return
        }
        if !decelerate {
            self.applyPendingEntriesIfPossible()
            self.maybeEnsureAtLatestIfNeeded()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.applyPendingEntriesIfPossible()
        self.maybeEnsureAtLatestIfNeeded()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.applyPendingEntriesIfPossible()
        self.maybeEnsureAtLatestIfNeeded()
    }
    
    // MARK: - UITextViewDelegate
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: textView)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backPressed() {
        self.actions.back?()
    }
    
    @objc private func profilePressed() {
        self.actions.openProfile?()
    }
    
    @objc private func attachPressed() {
        guard self.isComposerEnabled else {
            return
        }
        self.actions.openAttachments?()
    }
    
    @objc private func recordPressed() {
        guard self.isComposerEnabled else {
            return
        }
        guard let state = self.interfaceState else {
            return
        }
        if state.inputTextPanelState.mediaRecordingState != nil {
            self.actions.finishVoiceRecordingAndSend?()
        } else {
            self.actions.beginVoiceRecording?()
        }
    }
    
    @objc private func sendPressed() {
        guard self.isComposerEnabled else {
            return
        }
        let text = self.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        self.actions.sendText?(text)
        self.inputTextView.text = ""
    }
    
    @objc private func refreshTriggered() {
        guard self.refreshControl.isRefreshing else {
            return
        }
        self.triggerLoadEarlierRequest()
    }

    public override func accessibilityPerformEscape() -> Bool {
        if let back = self.actions.back {
            back()
            return true
        }
        return false
    }
    
    // MARK: - Helpers
    
    private func applyPendingEntriesIfPossible(force: Bool = false) {
        guard let entries = self.pendingEntries else {
            return
        }
        if !force && (self.tableView.isDragging || self.tableView.isDecelerating) {
            return
        }
        self.pendingEntries = nil
        self.applyEntries(entries)
    }
    
    private func applyEntries(_ entries: [ChatHistoryEntry]) {
        let incomingRows = self.makeRows(from: entries)
        let newRows = self.mergeRows(existing: self.rows, incoming: incomingRows)
        
        let previousWasNearBottom = self.isNearBottom()
        let previousWasWaitingForLoadEarlier = self.isWaitingForLoadEarlier
        let previousOldestIndex = self.rows.first?.index
        let loadEarlierAnchor = previousWasWaitingForLoadEarlier ? self.loadEarlierScrollAnchor : nil
        var loadEarlierRestoredIndexPath: IndexPath?

        let previousStableIds = self.rows.map { $0.stableId }
        let newStableIds = newRows.map { $0.stableId }
        if previousStableIds == newStableIds {
            if self.refreshControl.isRefreshing, !previousWasWaitingForLoadEarlier {
                self.refreshControl.endRefreshing()
            }
            return
        }

        self.loadEarlierNoProgressCount = 0
        var anchorStableId: UInt64?
        var anchorOffset: CGFloat = 0.0
        if !previousWasNearBottom {
            let rowOffset = self.loadEarlierRowOffset
            if let anchorIndexPath = self.tableView.indexPathsForVisibleRows?.sorted().first(where: { $0.row >= rowOffset && ($0.row - rowOffset) >= 0 && ($0.row - rowOffset) < self.rows.count }) {
                let anchorRowIndex = anchorIndexPath.row - rowOffset
                anchorStableId = self.rows[anchorRowIndex].stableId
                let rect = self.tableView.rectForRow(at: anchorIndexPath)
                anchorOffset = rect.minY - self.tableView.contentOffset.y
            }
        }

        self.rows = newRows

        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
        }

        if self.rows.isEmpty || !self.didInitialScrollToBottom {
            if !self.didInitialScrollToBottom {
                self.didInitialScrollToBottom = true
                self.scrollToBottom(animated: false)
                self.focusLastMessageIfPossible()
            }
        } else if self.forceScrollToBottomOnNextApply {
            self.forceScrollToBottomOnNextApply = false
            self.scrollToBottom(animated: false)
            self.focusLastMessageIfPossible()
        } else if let loadEarlierAnchor {
            let anchoredIndex: Int? = loadEarlierAnchor.messageId.flatMap { messageId in
                return self.rows.firstIndex(where: { row in
                    if case let .message(message) = row.kind {
                        return message.id == messageId
                    } else {
                        return false
                    }
                })
            } ?? self.rows.firstIndex(where: { $0.stableId == loadEarlierAnchor.stableId })
            
            if let anchoredIndex {
                let indexPath = IndexPath(row: anchoredIndex + self.loadEarlierRowOffset, section: 0)
                let rect = self.tableView.rectForRow(at: indexPath)
                let targetOffset = rect.minY - loadEarlierAnchor.offset
                let minOffset = -self.tableView.adjustedContentInset.top
                let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
                self.tableView.setContentOffset(CGPoint(x: 0.0, y: min(max(targetOffset, minOffset), maxOffset)), animated: false)
                loadEarlierRestoredIndexPath = indexPath
            }
        } else if previousWasNearBottom {
            self.scrollToBottom(animated: false)
        } else if let anchorStableId, let newIndex = self.rows.firstIndex(where: { $0.stableId == anchorStableId }) {
            let indexPath = IndexPath(row: newIndex + self.loadEarlierRowOffset, section: 0)
            let rect = self.tableView.rectForRow(at: indexPath)
            let targetOffset = rect.minY - anchorOffset
            let minOffset = -self.tableView.adjustedContentInset.top
            let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
            self.tableView.setContentOffset(CGPoint(x: 0.0, y: min(max(targetOffset, minOffset), maxOffset)), animated: false)
        }

        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }

        let didLoadEarlierProgress: Bool
        if previousWasWaitingForLoadEarlier, let before = self.loadEarlierOldestIndexBeforeRequest ?? previousOldestIndex, let after = self.rows.first?.index, after < before {
            didLoadEarlierProgress = true
            self.endWaitingForLoadEarlierIfNeeded()
            self.reloadLoadEarlierRow()
        } else {
            didLoadEarlierProgress = false
        }
        
        if didLoadEarlierProgress, UIAccessibility.isVoiceOverRunning, let loadEarlierRestoredIndexPath {
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                let focusTarget: Any?
                if let cell = self.tableView.cellForRow(at: loadEarlierRestoredIndexPath) {
                    focusTarget = cell
                } else {
                    focusTarget = self.tableView
                }
                UIAccessibility.post(notification: .layoutChanged, argument: focusTarget)
            }
        }
    }
    
    private func mergeRows(existing: [Row], incoming: [Row]) -> [Row] {
        guard !existing.isEmpty else {
            return incoming
        }
        guard !incoming.isEmpty else {
            return existing
        }
        
        var byStableId: [UInt64: Row] = [:]
        byStableId.reserveCapacity(existing.count + incoming.count)
        for row in existing {
            byStableId[row.stableId] = row
        }
        for row in incoming {
            byStableId[row.stableId] = row
        }
        
        var result = Array(byStableId.values)
        result.sort { lhs, rhs in
            if lhs.index != rhs.index {
                return lhs.index < rhs.index
            }
            return lhs.stableId < rhs.stableId
        }
        return result
    }
    
    private func triggerLoadEarlierRequest() {
        guard self.loadEarlierNoProgressCount < Self.maxLoadEarlierNoProgressCount else {
            return
        }
        guard self.canLoadEarlierHistory else {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            return
        }
        guard !self.isLoadEarlierInProgress else {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            return
        }
        self.loadEarlierScrollAnchor = self.currentScrollAnchor()
        self.loadEarlierOldestIndexBeforeRequest = self.rows.first?.index
        self.loadEarlierRequestId += 1
        let requestId = self.loadEarlierRequestId
        self.isWaitingForLoadEarlier = true
        self.lastLoadEarlierRequestTimestamp = CACurrentMediaTime()
        self.reloadLoadEarlierRow()
        self.actions.requestLoadEarlier?()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.loadEarlierTimeout) { [weak self] in
            guard let self else {
                return
            }
            guard self.isWaitingForLoadEarlier, self.loadEarlierRequestId == requestId else {
                return
            }
            self.endWaitingForLoadEarlierIfNeeded()
            self.loadEarlierNoProgressCount += 1
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.reloadLoadEarlierRow()
        }
    }

    private func reloadLoadEarlierRow() {
        UIView.performWithoutAnimation {
            if self.shouldShowLoadEarlierRow, self.tableView.numberOfRows(inSection: 0) > 0 {
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            } else {
                self.tableView.reloadData()
            }
            self.tableView.layoutIfNeeded()
        }
    }
    
    public override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        return self.tableView.accessibilityScroll(direction)
    }

    private func maybeEnsureAtLatestIfNeeded() {
        guard !self.isWaitingForLoadEarlier else {
            return
        }
        guard self.isAtBottom() else {
            return
        }
        self.scrollToBottom(animated: false)
        self.forceScrollToBottomOnNextApply = true
        self.actions.scrollToLatest?()
    }

    private func isAtBottom(epsilon: CGFloat = 2.0) -> Bool {
        let visibleHeight = self.tableView.bounds.height
        if visibleHeight <= 0.0 {
            return true
        }
        let minOffset = -self.tableView.adjustedContentInset.top
        let maxOffset = max(minOffset, self.tableView.contentSize.height - visibleHeight + self.tableView.adjustedContentInset.bottom)
        return maxOffset - self.tableView.contentOffset.y <= epsilon
    }

    private func endWaitingForLoadEarlierIfNeeded() {
        guard self.isWaitingForLoadEarlier else {
            return
        }
        self.isWaitingForLoadEarlier = false
        self.loadEarlierOldestIndexBeforeRequest = nil
        self.loadEarlierScrollAnchor = nil
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        self.actions.didEndLoadEarlier?()
    }

    private func currentScrollAnchor() -> ScrollAnchor? {
        let rowOffset = self.loadEarlierRowOffset
        
        func makeAnchor(for indexPath: IndexPath) -> ScrollAnchor? {
            let anchorRowIndex = indexPath.row - rowOffset
            guard anchorRowIndex >= 0, anchorRowIndex < self.rows.count else {
                return nil
            }
            let row = self.rows[anchorRowIndex]
            let stableId = row.stableId
            let messageId: MessageId?
            if case let .message(message) = row.kind {
                messageId = message.id
            } else {
                messageId = nil
            }
            let rect = self.tableView.rectForRow(at: indexPath)
            let offset = rect.minY - self.tableView.contentOffset.y
            return ScrollAnchor(stableId: stableId, messageId: messageId, offset: offset)
        }
        
        if UIAccessibility.isVoiceOverRunning, let focusedView = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView {
            var current: UIView? = focusedView
            while let view = current {
                if let cell = view as? UITableViewCell, cell.isDescendant(of: self.tableView) {
                    if let indexPath = self.tableView.indexPath(for: cell), indexPath.row >= rowOffset {
                        let rowIndex = indexPath.row - rowOffset
                        if rowIndex >= 0, rowIndex < self.rows.count, case .message = self.rows[rowIndex].kind {
                            if let anchor = makeAnchor(for: indexPath) {
                                return anchor
                            }
                        }
                    }
                    break
                }
                current = view.superview
            }
        }
        
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.sorted() else {
            return nil
        }
        
        for indexPath in visibleIndexPaths {
            guard indexPath.row >= rowOffset else {
                continue
            }
            let rowIndex = indexPath.row - rowOffset
            guard rowIndex >= 0, rowIndex < self.rows.count else {
                continue
            }
            if case .message = self.rows[rowIndex].kind {
                if let anchor = makeAnchor(for: indexPath) {
                    return anchor
                }
            }
        }
        
        if let indexPath = visibleIndexPaths.first(where: { $0.row >= rowOffset && ($0.row - rowOffset) >= 0 && ($0.row - rowOffset) < self.rows.count }) {
            return makeAnchor(for: indexPath)
        }
        
        return nil
    }
    
    private func resolveRow(_ row: Row, state: ChatPresentationInterfaceState) -> (title: String, subtitle: String?, accessibilityLabel: String, hint: String?, traits: UIAccessibilityTraits) {
        switch row.kind {
        case let .message(message):
            return self.resolveMessageRow(message: message, state: state)
        case let .info(text):
            let title = text
            return (title, nil, title, nil, [.staticText])
        }
    }
    
    private func resolveMessageRow(message: Message, state: ChatPresentationInterfaceState) -> (title: String, subtitle: String?, accessibilityLabel: String, hint: String?, traits: UIAccessibilityTraits) {
        let isIncoming = message.effectivelyIncoming(state.accountPeerId)
        
        var announceIncomingAuthors = false
        if let chatPeer = message.peers[message.id.peerId] {
            if chatPeer is TelegramGroup {
                announceIncomingAuthors = true
            } else if let channel = chatPeer as? TelegramChannel, case .group = channel.info {
                announceIncomingAuthors = true
            }
        }
        
        let authorName: String? = message.author.flatMap(EnginePeer.init)?.displayTitle(strings: state.strings, displayOrder: state.nameDisplayOrder)
        let subtitle: String?
        if isIncoming {
            subtitle = announceIncomingAuthors ? authorName : nil
        } else {
            subtitle = state.strings.DialogList_You
        }
        
        var title = descriptionStringForMessage(
            contentSettings: ContentSettings.default,
            message: EngineMessage(message),
            strings: state.strings,
            nameDisplayOrder: state.nameDisplayOrder,
            dateTimeFormat: state.dateTimeFormat,
            accountPeerId: state.accountPeerId
        ).0.string.trimmingCharacters(in: .whitespacesAndNewlines)
        var accessibilityLabel = ""
        var hint: String?
        var traits: UIAccessibilityTraits = [.staticText]
        
        if title.isEmpty {
            if let service = plainServiceMessageString(strings: state.strings, nameDisplayOrder: state.nameDisplayOrder, dateTimeFormat: state.dateTimeFormat, message: EngineMessage(message), accountPeerId: state.accountPeerId, forChatList: false, forForumOverview: false)?.text {
                let trimmed = service.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    title = trimmed
                }
            }
            for media in message.media {
                if let action = media as? TelegramMediaAction {
                    if case let .customText(text, _, _) = action.action {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            title = trimmed
                            break
                        }
                    }
                }
            }
            if title.isEmpty {
                title = state.strings.VoiceOver_Chat_Message
            }
        }
        
        for media in message.media {
            if let _ = media as? TelegramMediaImage {
                traits.insert(.image)
                if isIncoming {
                    if announceIncomingAuthors, let authorName {
                        accessibilityLabel = state.strings.VoiceOver_Chat_PhotoFrom(authorName).string
                    } else {
                        accessibilityLabel = state.strings.VoiceOver_Chat_Photo
                    }
                } else {
                    accessibilityLabel = state.strings.VoiceOver_Chat_YourPhoto
                }
                if !message.text.isEmpty {
                    accessibilityLabel.append(". ")
                    accessibilityLabel.append(state.strings.VoiceOver_Chat_Caption(message.text).string)
                }
                hint = state.strings.VoiceOver_Chat_OpenHint
                return (state.strings.VoiceOver_Chat_Photo, subtitle, accessibilityLabel, hint, traits)
            } else if let file = media as? TelegramMediaFile {
                if file.isVoice {
                    traits.insert(.startsMediaSession)
                    if isIncoming {
                        if announceIncomingAuthors, let authorName {
                            accessibilityLabel = state.strings.VoiceOver_Chat_VoiceMessageFrom(authorName).string
                        } else {
                            accessibilityLabel = state.strings.VoiceOver_Chat_VoiceMessage
                        }
                    } else {
                        accessibilityLabel = state.strings.VoiceOver_Chat_YourVoiceMessage
                    }
                    if let duration = file.duration, let durationString = Self.voiceMessageDurationFormatter.string(from: Double(duration)) {
                        accessibilityLabel.append(". ")
                        accessibilityLabel.append(state.strings.VoiceOver_Chat_Duration(durationString).string)
                    }
                    hint = state.strings.VoiceOver_Chat_PlayHint
                    return (state.strings.VoiceOver_Chat_VoiceMessage, subtitle, accessibilityLabel, hint, traits)
                } else {
                    let sizeString = Self.fileSizeFormatter.string(fromByteCount: Int64(file.size ?? 0))
                    if isIncoming {
                        if announceIncomingAuthors, let authorName {
                            accessibilityLabel = state.strings.VoiceOver_Chat_FileFrom(authorName).string
                        } else {
                            accessibilityLabel = state.strings.VoiceOver_Chat_File
                        }
                    } else {
                        accessibilityLabel = state.strings.VoiceOver_Chat_YourFile
                    }
                    if let fileName = file.fileName, !fileName.isEmpty {
                        accessibilityLabel.append(". ")
                        accessibilityLabel.append(fileName)
                    }
                    accessibilityLabel.append(". ")
                    accessibilityLabel.append(state.strings.VoiceOver_Chat_Size(sizeString).string)
                    hint = state.strings.VoiceOver_Chat_OpenHint
                    return (state.strings.VoiceOver_Chat_File, subtitle, accessibilityLabel, hint, traits)
                }
            }
        }
        
        if isIncoming, announceIncomingAuthors, let authorName {
            accessibilityLabel = "\(authorName). \(title)"
        } else if !isIncoming {
            accessibilityLabel = "\(state.strings.DialogList_You). \(title)"
        } else {
            accessibilityLabel = title
        }
        
        return (title, subtitle, accessibilityLabel, nil, traits)
    }

    private func isMessageActivatable(_ message: Message) -> Bool {
        for media in message.media {
            if media is TelegramMediaImage {
                return true
            }
            if media is TelegramMediaFile {
                return true
            }
        }
        return false
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

    private func scrollToBottom(animated: Bool) {
        guard !self.rows.isEmpty else {
            return
        }
        let indexPath = IndexPath(row: self.rows.count - 1 + self.loadEarlierRowOffset, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    private func scrollToTop(animated: Bool) {
        let minOffset = -self.tableView.adjustedContentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0.0, y: minOffset), animated: animated)
    }
    
    private func focusLastMessageIfPossible() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard !self.rows.isEmpty else {
            return
        }
        let lastIndexPath = IndexPath(row: self.rows.count - 1 + self.loadEarlierRowOffset, section: 0)
        if let cell = self.tableView.cellForRow(at: lastIndexPath) {
            UIAccessibility.post(notification: .screenChanged, argument: cell)
        }
    }
    
    private func setupKeyboardObservers() {
        let nc = NotificationCenter.default
        let token = nc.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] notification in
            self?.handleKeyboard(notification: notification)
        }
        self.keyboardObservers.append(token)
    }
    
    private func handleKeyboard(notification: Notification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let endFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let endFrameInScreen = endFrameValue.cgRectValue
        let endFrame = self.convert(endFrameInScreen, from: nil)
        let overlap = max(0.0, self.bounds.maxY - endFrame.minY - self.safeAreaInsets.bottom)
        
        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))
        
        self.composerBottomConstraint?.constant = -overlap
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [curve, .beginFromCurrentState]) {
            self.layoutIfNeeded()
        }
    }
}

extension ChatVoiceOverOverlayView: UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
}
