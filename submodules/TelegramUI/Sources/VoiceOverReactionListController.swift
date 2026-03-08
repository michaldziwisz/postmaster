import UIKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting
import AccountContext

private enum VoiceOverReactionListRow {
    case summary(title: String, subtitle: String?)
    case filter(title: String, subtitle: String?, reaction: MessageReaction.Reaction?)
    case entry(EngineMessageReactionListContext.Item)
    case loading
}

private struct VoiceOverReactionListSection {
    let rows: [VoiceOverReactionListRow]
}

final class VoiceOverReactionListController: UITableViewController, UIAdaptivePresentationControllerDelegate {
    private let context: AccountContext
    private let presentationData: PresentationData
    private let availableReactions: AvailableReactions?
    private let message: EngineMessage
    private let readStats: MessageReadStats?
    private let openPeer: (EnginePeer, Bool) -> Void
    private let onDismiss: (() -> Void)?
    
    private var selectedReaction: MessageReaction.Reaction?
    private var listContext: EngineMessageReactionListContext?
    private var listState: EngineMessageReactionListContext.State
    private var stateDisposable: Disposable?
    private var reactionTitlesDisposable: Disposable?
    private var reactionTitles: [MessageReaction.Reaction: String] = [:]
    private var sections: [VoiceOverReactionListSection] = []
    private var didRunOnDismiss = false
    private var isLoadingInitial = false
    
    init(
        context: AccountContext,
        presentationData: PresentationData,
        availableReactions: AvailableReactions?,
        message: EngineMessage,
        reaction: MessageReaction.Reaction?,
        readStats: MessageReadStats?,
        openPeer: @escaping (EnginePeer, Bool) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.context = context
        self.presentationData = presentationData
        self.availableReactions = availableReactions
        self.message = message
        self.selectedReaction = reaction
        self.readStats = readStats
        self.openPeer = openPeer
        self.onDismiss = onDismiss
        self.listState = EngineMessageReactionListContext.State(message: message, readStats: readStats, reaction: reaction)
        
        super.init(style: .insetGrouped)
        
        self.prefillReactionTitles()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.stateDisposable?.dispose()
        self.reactionTitlesDisposable?.dispose()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.screenTitle()
        self.navigationItem.largeTitleDisplayMode = .never
        self.view.backgroundColor = .systemBackground
        self.view.accessibilityViewIsModal = UIAccessibility.isVoiceOverRunning
        self.presentationController?.delegate = self
        
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 60.0
        self.tableView.cellLayoutMarginsFollowReadableWidth = true
        
        let backButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: self, action: #selector(self.backPressed))
        backButtonItem.accessibilityLabel = self.presentationData.strings.Common_Back
        self.navigationItem.leftBarButtonItem = backButtonItem
        
        self.resolveCustomReactionTitles()
        self.reloadListContext(scrollToTop: false, announce: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.presentationController?.delegate = self
        
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sections[section].rows.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.sections[indexPath.section].rows[indexPath.row]
        let identifier: String
        let style: UITableViewCell.CellStyle
        
        switch row {
        case .loading:
            identifier = "VoiceOverReactionLoadingCell"
            style = .default
        default:
            identifier = "VoiceOverReactionCell"
            style = .subtitle
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: style, reuseIdentifier: identifier)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.imageView?.image = nil
        cell.accessoryType = .none
        cell.selectionStyle = .none
        cell.isAccessibilityElement = true
        cell.accessibilityHint = nil
        
        switch row {
        case let .summary(title, subtitle):
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = subtitle
            cell.accessibilityLabel = self.combinedAccessibilityLabel(title: title, subtitle: subtitle)
            cell.accessibilityTraits = .staticText
        case let .filter(title, subtitle, reaction):
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = subtitle
            cell.selectionStyle = .default
            cell.accessoryType = self.selectedReaction == reaction ? .checkmark : .none
            cell.accessibilityLabel = self.combinedAccessibilityLabel(title: title, subtitle: subtitle)
            cell.accessibilityTraits = [.button]
        case let .entry(item):
            let title = item.peer.displayTitle(strings: self.presentationData.strings, displayOrder: self.presentationData.nameDisplayOrder)
            let subtitle = self.entrySubtitle(for: item)
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = subtitle
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.accessibilityLabel = self.combinedAccessibilityLabel(title: title, subtitle: subtitle)
            cell.accessibilityHint = self.presentationData.strings.Conversation_ContextMenuOpenProfile
            cell.accessibilityTraits = [.button]
        case .loading:
            cell.textLabel?.text = "Loading…"
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = "Loading…"
            cell.accessibilityTraits = .staticText
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let row = self.sections[indexPath.section].rows[indexPath.row]
        switch row {
        case let .filter(_, _, reaction):
            guard self.selectedReaction != reaction else {
                return
            }
            self.selectedReaction = reaction
            self.title = self.screenTitle()
            self.reloadListContext(scrollToTop: true, announce: true)
        case let .entry(item):
            let openPeer = self.openPeer
            self.dismiss(animated: true, completion: { [weak self] in
                self?.runOnDismiss()
                openPeer(item.peer, item.reaction != nil)
            })
        case .summary, .loading:
            break
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.listState.canLoadMore, let listContext = self.listContext else {
            return
        }
        let remainingDistance = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height
        if remainingDistance < max(200.0, scrollView.bounds.height * 0.75) {
            listContext.loadMore()
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.backPressed()
        return true
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.runOnDismiss()
    }
    
    @objc private func backPressed() {
        self.dismiss(animated: true, completion: { [weak self] in
            self?.runOnDismiss()
        })
    }
    
    private func runOnDismiss() {
        guard !self.didRunOnDismiss else {
            return
        }
        self.didRunOnDismiss = true
        self.onDismiss?()
    }
    
    private func prefillReactionTitles() {
        if let availableReactions = self.availableReactions {
            for availableReaction in availableReactions.reactions {
                let title = availableReaction.title.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    self.reactionTitles[availableReaction.value] = title
                }
            }
        }
        
        if let reactionsAttribute = self.message._asMessage().reactionsAttribute {
            for reaction in reactionsAttribute.reactions {
                switch reaction.value {
                case let .builtin(value):
                    if self.reactionTitles[reaction.value] == nil {
                        self.reactionTitles[reaction.value] = value
                    }
                case .stars:
                    if self.reactionTitles[reaction.value] == nil {
                        self.reactionTitles[reaction.value] = "⭐️"
                    }
                case .custom:
                    break
                }
            }
        }
    }
    
    private func resolveCustomReactionTitles() {
        guard let reactionsAttribute = self.message._asMessage().reactionsAttribute else {
            return
        }
        
        let customFileIds = reactionsAttribute.reactions.compactMap { reaction -> Int64? in
            if case let .custom(fileId) = reaction.value {
                return fileId
            } else {
                return nil
            }
        }
        
        guard !customFileIds.isEmpty else {
            return
        }
        
        self.reactionTitlesDisposable = (self.context.engine.stickers.resolveInlineStickers(fileIds: customFileIds)
        |> deliverOnMainQueue).startStrict(next: { [weak self] files in
            guard let self else {
                return
            }
            for (fileId, file) in files {
                var title = "Custom Emoji"
                for attribute in file.attributes {
                    if case let .CustomEmoji(_, _, alt, _) = attribute {
                        let normalized = alt.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !normalized.isEmpty {
                            title = normalized
                        }
                        break
                    }
                }
                self.reactionTitles[.custom(fileId)] = title
            }
            self.title = self.screenTitle()
            self.rebuildSections()
        })
    }
    
    private func reloadListContext(scrollToTop: Bool, announce: Bool) {
        self.stateDisposable?.dispose()
        
        let selectedReaction = self.selectedReaction
        let context = self.context.engine.messages.messageReactionList(message: self.message, readStats: self.readStats, reaction: selectedReaction)
        self.listContext = context
        self.listState = EngineMessageReactionListContext.State(message: self.message, readStats: self.readStats, reaction: selectedReaction)
        self.isLoadingInitial = self.listState.items.isEmpty && self.listState.canLoadMore
        self.rebuildSections()
        
        self.stateDisposable = (context.state
        |> deliverOnMainQueue).startStrict(next: { [weak self] state in
            guard let self else {
                return
            }
            self.listState = state
            self.isLoadingInitial = false
            self.rebuildSections()
        })
        
        if scrollToTop {
            self.tableView.setContentOffset(CGPoint(x: 0.0, y: -self.tableView.adjustedContentInset.top), animated: false)
        }
        
        if announce, UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                UIAccessibility.post(notification: .layoutChanged, argument: self.tableView)
            }
        }
    }
    
    private func rebuildSections() {
        var sections: [VoiceOverReactionListSection] = []
        
        let summaryRows = self.summaryRows()
        if !summaryRows.isEmpty {
            sections.append(VoiceOverReactionListSection(rows: summaryRows))
        }
        
        let filterRows = self.filterRows()
        if !filterRows.isEmpty {
            sections.append(VoiceOverReactionListSection(rows: filterRows))
        }
        
        let mergedItems = self.mergedItems()
        if !mergedItems.isEmpty {
            sections.append(VoiceOverReactionListSection(rows: mergedItems.map(VoiceOverReactionListRow.entry)))
        } else if self.isLoadingInitial {
            sections.append(VoiceOverReactionListSection(rows: [.loading]))
        }
        
        self.sections = sections
        self.tableView.reloadData()
    }
    
    private func summaryRows() -> [VoiceOverReactionListRow] {
        var rows: [VoiceOverReactionListRow] = []
        
        if self.selectedReaction == nil, let readStats = self.readStats, !readStats.peers.isEmpty {
            rows.append(.summary(title: self.readSummaryText(count: readStats.peers.count), subtitle: nil))
        }
        
        let reactionCount = self.selectedReaction.map { self.reactionCount(for: $0) } ?? self.totalReactionCount()
        if reactionCount > 0 {
            let subtitle: String?
            if let selectedReaction = self.selectedReaction {
                subtitle = self.reactionTitle(for: selectedReaction)
            } else {
                subtitle = nil
            }
            rows.append(.summary(title: self.presentationData.strings.Chat_ContextReactionCount(Int32(reactionCount)), subtitle: subtitle))
        }
        
        if rows.isEmpty, let readStats = self.readStats, readStats.peers.isEmpty, self.totalReactionCount() == 0 {
            rows.append(.summary(title: self.emptyStateText(), subtitle: nil))
        }
        
        return rows
    }
    
    private func filterRows() -> [VoiceOverReactionListRow] {
        let filters = self.availableFilters()
        return filters.map { filter in
            let subtitle: String?
            if filter.count > 0 {
                subtitle = "\(filter.count)"
            } else {
                subtitle = nil
            }
            return .filter(title: filter.title, subtitle: subtitle, reaction: filter.reaction)
        }
    }
    
    private func availableFilters() -> [(reaction: MessageReaction.Reaction?, title: String, count: Int)] {
        guard let reactionsAttribute = self.message._asMessage().reactionsAttribute, !reactionsAttribute.reactions.isEmpty else {
            return []
        }
        
        let reactions = reactionsAttribute.reactions.map { reaction -> (MessageReaction.Reaction?, String, Int) in
            return (reaction.value, self.reactionTitle(for: reaction.value), Int(reaction.count))
        }
        
        if reactions.count > 1 || ((self.readStats?.peers.isEmpty == false) && !reactions.isEmpty) {
            var filters: [(MessageReaction.Reaction?, String, Int)] = []
            filters.append((nil, self.presentationData.strings.Common_All, max(self.totalReactionCount(), self.readStats?.peers.count ?? 0)))
            filters.append(contentsOf: reactions)
            return filters
        } else {
            return []
        }
    }
    
    private func mergedItems() -> [EngineMessageReactionListContext.Item] {
        var items = self.listState.items
        if self.selectedReaction == nil, !self.listState.canLoadMore, let readStats = self.readStats {
            var existingPeerIds = Set(items.map(\.peer.id))
            for peer in readStats.peers {
                if !existingPeerIds.contains(peer.id) {
                    existingPeerIds.insert(peer.id)
                    items.append(EngineMessageReactionListContext.Item(peer: peer, reaction: nil, timestamp: readStats.readTimestamps[peer.id], timestampIsReaction: false))
                }
            }
        }
        return items
    }
    
    private func screenTitle() -> String {
        if let selectedReaction = self.selectedReaction {
            return self.reactionTitle(for: selectedReaction)
        }
        if self.totalReactionCount() > 0 {
            return self.presentationData.strings.PeerInfo_Reactions
        }
        if let readStats = self.readStats, !readStats.peers.isEmpty {
            return self.readSummaryText(count: readStats.peers.count)
        }
        return self.presentationData.strings.PeerInfo_Reactions
    }
    
    private func reactionTitle(for reaction: MessageReaction.Reaction) -> String {
        if let title = self.reactionTitles[reaction] {
            return title
        }
        switch reaction {
        case let .builtin(value):
            return value
        case .stars:
            return "⭐️"
        case .custom:
            return "Custom Emoji"
        }
    }
    
    private func totalReactionCount() -> Int {
        if let readStats = self.readStats, readStats.reactionCount > 0 {
            return readStats.reactionCount
        }
        return self.message._asMessage().reactionsAttribute?.reactions.reduce(0, { partialResult, reaction in
            partialResult + Int(reaction.count)
        }) ?? 0
    }
    
    private func reactionCount(for reaction: MessageReaction.Reaction) -> Int {
        return self.message._asMessage().reactionsAttribute?.reactions.first(where: { $0.value == reaction }).flatMap { Int($0.count) } ?? 0
    }
    
    private func readSummaryText(count: Int) -> String {
        for media in self.message.media {
            if let file = media as? TelegramMediaFile {
                if file.isVoice {
                    return self.presentationData.strings.Conversation_ContextMenuListened(Int32(count))
                } else if file.isInstantVideo {
                    return self.presentationData.strings.Conversation_ContextMenuWatched(Int32(count))
                }
            }
        }
        return self.presentationData.strings.Conversation_ContextMenuSeen(Int32(count))
    }
    
    private func emptyStateText() -> String {
        for media in self.message.media {
            if let file = media as? TelegramMediaFile {
                if file.isVoice {
                    return self.presentationData.strings.Conversation_ContextMenuNobodyListened
                } else if file.isInstantVideo {
                    return self.presentationData.strings.Conversation_ContextMenuNobodyWatched
                }
            }
        }
        return self.presentationData.strings.Conversation_ContextMenuNoViews
    }
    
    private func entrySubtitle(for item: EngineMessageReactionListContext.Item) -> String? {
        var components: [String] = []
        if self.selectedReaction == nil, let reaction = item.reaction {
            components.append(self.reactionTitle(for: reaction))
        }
        if let timestamp = item.timestamp {
            components.append(self.formattedTimestamp(timestamp))
        }
        if components.isEmpty {
            return nil
        } else {
            return components.joined(separator: " • ")
        }
    }
    
    private func formattedTimestamp(_ timestamp: Int32) -> String {
        return humanReadableStringForTimestamp(
            strings: self.presentationData.strings,
            dateTimeFormat: self.presentationData.dateTimeFormat,
            timestamp: timestamp,
            alwaysShowTime: true,
            allowYesterday: true,
            format: HumanReadableStringFormat(
                dateFormatString: { value in
                    PresentationStrings.FormattedString(string: value, ranges: [])
                },
                tomorrowFormatString: { value in
                    PresentationStrings.FormattedString(string: value, ranges: [])
                },
                todayFormatString: { value in
                    PresentationStrings.FormattedString(string: value, ranges: [])
                },
                yesterdayFormatString: { value in
                    PresentationStrings.FormattedString(string: value, ranges: [])
                }
            )
        ).string
    }
    
    private func combinedAccessibilityLabel(title: String, subtitle: String?) -> String {
        if let subtitle, !subtitle.isEmpty {
            return "\(title), \(subtitle)"
        } else {
            return title
        }
    }
}

func presentVoiceOverReactionListController(
    from rootViewController: UIViewController,
    context: AccountContext,
    presentationData: PresentationData,
    availableReactions: AvailableReactions?,
    message: Message,
    reaction: MessageReaction.Reaction?,
    readStats: MessageReadStats?,
    onDismiss: (() -> Void)? = nil,
    openPeer: @escaping (EnginePeer, Bool) -> Void
) {
    let controller = VoiceOverReactionListController(
        context: context,
        presentationData: presentationData,
        availableReactions: availableReactions,
        message: EngineMessage(message),
        reaction: reaction,
        readStats: readStats,
        openPeer: openPeer,
        onDismiss: onDismiss
    )
    let navigationController = UINavigationController(rootViewController: controller)
    navigationController.modalPresentationStyle = .fullScreen
    navigationController.isModalInPresentation = false
    navigationController.view.accessibilityViewIsModal = true
    
    var presenter = rootViewController
    while let presentedViewController = presenter.presentedViewController {
        presenter = presentedViewController
    }
    presenter.present(navigationController, animated: true)
}
