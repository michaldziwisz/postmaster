import Foundation
import UIKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ChatPresentationInterfaceState
import TelegramStringFormatting
import ChatHistoryEntry
import TelegramUIPreferences

public final class ChatVoiceOverOverlayView: UIView {
    public struct Actions {
        public var back: (() -> Void)?
        public var openProfile: (() -> Void)?
        public var openAttachments: (() -> Void)?
        public var sendText: ((String) -> Void)?
        public var beginVoiceRecording: (() -> Void)?
        public var finishVoiceRecordingAndSend: (() -> Void)?
        public var requestLoadEarlier: (() -> Void)?
        public var activateMessage: ((Message) -> Void)?
        
        public init(
            back: (() -> Void)? = nil,
            openProfile: (() -> Void)? = nil,
            openAttachments: (() -> Void)? = nil,
            sendText: ((String) -> Void)? = nil,
            beginVoiceRecording: (() -> Void)? = nil,
            finishVoiceRecordingAndSend: (() -> Void)? = nil,
            requestLoadEarlier: (() -> Void)? = nil,
            activateMessage: ((Message) -> Void)? = nil
        ) {
            self.back = back
            self.openProfile = openProfile
            self.openAttachments = openAttachments
            self.sendText = sendText
            self.beginVoiceRecording = beginVoiceRecording
            self.finishVoiceRecordingAndSend = finishVoiceRecordingAndSend
            self.requestLoadEarlier = requestLoadEarlier
            self.activateMessage = activateMessage
        }
    }
    
    private struct Row {
        enum Kind {
            case message(Message)
            case info(String)
        }
        
        var stableId: UInt64
        var kind: Kind
    }
    
    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let profileButton = UIButton(type: .system)
    
    private let tableView = UITableView(frame: .zero, style: .plain)
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
    
    private var didInitialScrollToBottom = false
    private var pendingEntries: [ChatHistoryEntry]?
    private var isWaitingForLoadEarlier = false
    private var lastLoadEarlierRequestTimestamp: CFTimeInterval = 0.0
    private var loadEarlierRequestId: Int = 0
    
    public var actions = Actions()
    
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
        self.tableView.estimatedRowHeight = 56.0
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
        
        self.inputTextView.accessibilityLabel = state.strings.Conversation_InputTextPlaceholder
        self.inputTextView.accessibilityHint = nil
        
        self.updateRecordButton(state: state)
        self.updateTitle(state: state)
    }
    
    func updateEntries(_ entries: [ChatHistoryEntry]) {
        self.pendingEntries = entries
        self.applyPendingEntriesIfPossible()
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
        
        for entry in entries {
            switch entry {
            case let .MessageEntry(message, _, _, _, _, _):
                result.append(Row(stableId: entry.stableId, kind: .message(message)))
            case let .MessageGroupEntry(_, messages, _):
                if let message = messages.last?.0 {
                    result.append(Row(stableId: entry.stableId, kind: .message(message)))
                }
            case .UnreadEntry:
                break
            case let .ChatInfoEntry(info, _):
                switch info {
                case let .botInfo(title, text, _, _):
                    let combined = "\(title)\n\(text)"
                    result.append(Row(stableId: entry.stableId, kind: .info(combined)))
                case let .userInfo(peer, _, _, _, _):
                    result.append(Row(stableId: entry.stableId, kind: .info(peer.displayTitle(strings: self.interfaceState?.strings ?? defaultPresentationStrings, displayOrder: PresentationPersonNameOrder.firstLast))))
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
        return self.rows.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let current = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = current
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        
        cell.selectionStyle = .default
        cell.isAccessibilityElement = true
        
        guard let state = self.interfaceState else {
            cell.textLabel?.text = ""
            cell.accessibilityLabel = ""
            cell.accessibilityTraits = [.staticText]
            return cell
        }
        
        let row = self.rows[indexPath.row]
        let resolved = self.resolveRow(row, state: state)
        
        cell.textLabel?.text = resolved.title
        cell.textLabel?.textColor = state.theme.list.itemPrimaryTextColor
        cell.detailTextLabel?.text = resolved.subtitle
        cell.detailTextLabel?.textColor = state.theme.list.itemSecondaryTextColor
        
        cell.accessibilityLabel = resolved.accessibilityLabel
        cell.accessibilityHint = resolved.hint
        cell.accessibilityTraits = resolved.traits
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = self.rows[indexPath.row]
        if case let .message(message) = row.kind {
            self.actions.activateMessage?(message)
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        guard !self.isWaitingForLoadEarlier else {
            return
        }
        let threshold: CGFloat = 120.0
        if scrollView.contentOffset.y <= threshold {
            let now = CACurrentMediaTime()
            if now - self.lastLoadEarlierRequestTimestamp >= 1.0 {
                self.lastLoadEarlierRequestTimestamp = now
                self.triggerLoadEarlierRequest()
            }
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === self.tableView else {
            return
        }
        if !decelerate {
            self.applyPendingEntriesIfPossible()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.applyPendingEntriesIfPossible()
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
        self.actions.openAttachments?()
    }
    
    @objc private func recordPressed() {
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

    override func accessibilityPerformEscape() -> Bool {
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
        let newRows = self.makeRows(from: entries)
        
        let previousWasNearBottom = self.isNearBottom()
        let previousContentHeight = self.tableView.contentSize.height
        let previousContentOffsetY = self.tableView.contentOffset.y
        let previousStableIds = self.rows.map { $0.stableId }
        let newStableIds = newRows.map { $0.stableId }
        
        if previousStableIds == newStableIds {
            return
        }
        
        if self.rows.isEmpty || !self.didInitialScrollToBottom {
            self.rows = newRows
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            
            if !self.didInitialScrollToBottom {
                self.didInitialScrollToBottom = true
                self.scrollToBottom(animated: false)
                self.focusLastMessageIfPossible()
            }
            
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
            self.isWaitingForLoadEarlier = false
            return
        }
        
        if newStableIds.count > previousStableIds.count, Array(newStableIds.suffix(previousStableIds.count)) == previousStableIds {
            let insertedCount = newStableIds.count - previousStableIds.count
            self.rows = newRows
            
            UIView.performWithoutAnimation {
                self.tableView.performBatchUpdates {
                    let indexPaths = (0 ..< insertedCount).map { IndexPath(row: $0, section: 0) }
                    self.tableView.insertRows(at: indexPaths, with: .none)
                } completion: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.tableView.layoutIfNeeded()
                    let delta = self.tableView.contentSize.height - previousContentHeight
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: previousContentOffsetY + delta), animated: false)
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                    self.isWaitingForLoadEarlier = false
                }
            }
            
            return
        }
        
        if newStableIds.count > previousStableIds.count, Array(newStableIds.prefix(previousStableIds.count)) == previousStableIds {
            let insertedCount = newStableIds.count - previousStableIds.count
            self.rows = newRows
            
            UIView.performWithoutAnimation {
                self.tableView.performBatchUpdates {
                    let startIndex = previousStableIds.count
                    let indexPaths = (0 ..< insertedCount).map { IndexPath(row: startIndex + $0, section: 0) }
                    self.tableView.insertRows(at: indexPaths, with: .none)
                } completion: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                    self.isWaitingForLoadEarlier = false
                    if previousWasNearBottom {
                        self.scrollToBottom(animated: false)
                    }
                }
            }
            
            return
        }
        
        self.rows = newRows
        self.tableView.reloadData()
        if previousWasNearBottom {
            self.scrollToBottom(animated: false)
        }
        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }
        self.isWaitingForLoadEarlier = false
    }
    
    private func triggerLoadEarlierRequest() {
        self.loadEarlierRequestId += 1
        let requestId = self.loadEarlierRequestId
        self.isWaitingForLoadEarlier = true
        self.actions.requestLoadEarlier?()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self else {
                return
            }
            guard self.isWaitingForLoadEarlier, self.loadEarlierRequestId == requestId else {
                return
            }
            self.isWaitingForLoadEarlier = false
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
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
        
        var title = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        var accessibilityLabel = ""
        var hint: String?
        var traits: UIAccessibilityTraits = [.button]
        
        if title.isEmpty {
            title = state.strings.VoiceOver_Chat_Message
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
    
    private func scrollToBottom(animated: Bool) {
        guard !self.rows.isEmpty else {
            return
        }
        let indexPath = IndexPath(row: self.rows.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    private func focusLastMessageIfPossible() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard !self.rows.isEmpty else {
            return
        }
        let lastIndexPath = IndexPath(row: self.rows.count - 1, section: 0)
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
