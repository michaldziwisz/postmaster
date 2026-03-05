import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramCore
import Postbox
import TextFormat

final class VoiceOverPollResultsController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Section: Int, CaseIterable {
        case summary
        case options
        case info
    }
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private let messageId: MessageId
    private let poll: TelegramMediaPoll
    
    private let resultsContext: PollResultsContext
    private var resultsState: PollResultsState?
    private var resultsDisposable: Disposable?
    
    private let tableView: UITableView
    private let tableNode: ASDisplayNode
    
    private let isMultipleChoice: Bool
    private let isAnonymous: Bool
    
    private var optionCountsByOpaqueIdentifier: [Data: Int32] = [:]
    private var optionPercentsByOpaqueIdentifier: [Data: Int] = [:]
    private var totalVoters: Int32 = 0
    
    init(context: AccountContext, messageId: MessageId, poll: TelegramMediaPoll) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.messageId = messageId
        self.poll = poll
        
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)
        
        switch poll.kind {
        case let .poll(multipleAnswers):
            self.isMultipleChoice = multipleAnswers
        case .quiz:
            self.isMultipleChoice = false
        }
        
        self.isAnonymous = (poll.publicity == .anonymous)
        
        self.resultsContext = context.engine.messages.pollResults(messageId: messageId, poll: poll)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title = self.presentationData.strings.PollResults_Title
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Close, style: .plain, target: self, action: #selector(self.closePressed))
        
        self.recomputeStats()
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
            self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationTheme: presentationData.theme, presentationStrings: presentationData.strings), transition: .immediate)
            self.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
            self.title = presentationData.strings.PollResults_Title
            self.navigationItem.leftBarButtonItem?.title = presentationData.strings.Common_Close
            self.tableView.reloadData()
        })
        
        self.resultsDisposable = (self.resultsContext.state
        |> deliverOnMainQueue).startStrict(next: { [weak self] state in
            guard let self else {
                return
            }
            self.resultsState = state
            self.recomputeStats(resultsState: state)
            self.tableView.reloadData()
        })
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.estimatedRowHeight = 56.0
        self.tableView.rowHeight = UITableView.automaticDimension
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.resultsDisposable?.dispose()
    }
    
    override func loadView() {
        super.loadView()
        
        if let navigationBar = self.navigationBar {
            self.displayNode.insertSubnode(self.tableNode, belowSubnode: navigationBar)
        } else {
            self.displayNode.addSubnode(self.tableNode)
        }
        self.view.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        self.tableView.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        self.tableView.contentInsetAdjustmentBehavior = .never
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        let navigationHeight = max(0.0, self.cleanNavigationHeight)
        self.updateTableLayout(size: layout.size, safeInsets: layout.safeInsets, navigationHeight: navigationHeight, transition: transition)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let navigationHeight = max(0.0, self.cleanNavigationHeight)
        self.updateTableLayout(size: self.view.bounds.size, safeInsets: self.view.safeAreaInsets, navigationHeight: navigationHeight, transition: nil)
    }
    
    private func updateTableLayout(size: CGSize, safeInsets: UIEdgeInsets, navigationHeight: CGFloat, transition: ContainedViewLayoutTransition?) {
        let frame = CGRect(origin: .zero, size: size)
        if let transition {
            transition.updateFrame(node: self.tableNode, frame: frame)
        } else {
            self.tableNode.frame = frame
        }
        
        let insets = UIEdgeInsets(top: navigationHeight, left: 0.0, bottom: safeInsets.bottom, right: 0.0)
        self.tableView.contentInset = insets
        self.tableView.scrollIndicatorInsets = insets
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
        }
    }
    
    // MARK: - Actions
    
    @objc private func closePressed() {
        self.dismiss()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.closePressed()
        return true
    }
    
    private func recomputeStats() {
        self.recomputeStats(resultsState: self.resultsState)
    }
    
    private func recomputeStats(resultsState: PollResultsState?) {
        var counts: [Data: Int32] = [:]
        
        if let resultsState {
            for option in self.poll.options {
                if let optionState = resultsState.options[option.opaqueIdentifier] {
                    counts[option.opaqueIdentifier] = Int32(optionState.count)
                }
            }
        } else if let voters = self.poll.results.voters {
            for voter in voters {
                counts[voter.opaqueIdentifier] = voter.count
            }
        }
        
        self.optionCountsByOpaqueIdentifier = counts
        
        let total: Int32
        if let totalVoters = self.poll.results.totalVoters {
            total = totalVoters
        } else {
            total = counts.values.reduce(0, +)
        }
        self.totalVoters = total
        
        var percents: [Data: Int] = [:]
        if total > 0 {
            let votes = self.poll.options.map { Int(self.optionCountsByOpaqueIdentifier[$0.opaqueIdentifier] ?? 0) }
            let computed = countNicePercent(votes: votes, total: Int(total))
            for (index, option) in self.poll.options.enumerated() {
                if index < computed.count {
                    percents[option.opaqueIdentifier] = computed[index]
                }
            }
        }
        self.optionPercentsByOpaqueIdentifier = percents
    }
    
    private func optionCountText(_ count: Int32) -> String {
        switch self.poll.kind {
        case .poll:
            return count == 0 ? self.presentationData.strings.MessagePoll_NoVotes : self.presentationData.strings.MessagePoll_VotedCount(count)
        case .quiz:
            return count == 0 ? self.presentationData.strings.MessagePoll_QuizNoUsers : self.presentationData.strings.MessagePoll_QuizCount(count)
        }
    }
    
    private func summaryText() -> String {
        var parts: [String] = []
        
        switch self.poll.kind {
        case .quiz:
            parts.append(self.presentationData.strings.CreatePoll_Quiz)
        case .poll:
            parts.append(self.presentationData.strings.MessagePoll_LabelPoll)
        }
        
        if self.isMultipleChoice {
            parts.append(self.presentationData.strings.CreatePoll_MultipleChoice)
        }
        
        if self.isAnonymous {
            parts.append(self.presentationData.strings.CreatePoll_Anonymous)
        }
        
        if self.totalVoters > 0 {
            parts.append(self.presentationData.strings.MessagePoll_VotedCount(self.totalVoters))
        } else {
            parts.append(self.presentationData.strings.MessagePoll_NoVotes)
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func optionAccessibilityValue(option: TelegramMediaPollOption) -> String {
        let count = self.optionCountsByOpaqueIdentifier[option.opaqueIdentifier] ?? 0
        let percent = self.optionPercentsByOpaqueIdentifier[option.opaqueIdentifier] ?? 0
        return "\(percent)%, \(self.optionCountText(count))"
    }
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isAnonymous {
            return Section.allCases.count
        } else {
            return Section.allCases.count - 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .summary {
        case .summary:
            return 1
        case .options:
            return self.poll.options.count
        case .info:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .summary {
        case .summary:
            return nil
        case .options:
            return self.presentationData.strings.CreatePoll_OptionsHeader
        case .info:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .summary {
        case .summary:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = self.poll.text
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = self.summaryText()
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = self.poll.text
            cell.accessibilityValue = self.summaryText()
            cell.accessibilityTraits = [.staticText]
            return cell
            
        case .options:
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.numberOfLines = 0
            
            if indexPath.row < self.poll.options.count {
                let option = self.poll.options[indexPath.row]
                let value = self.optionAccessibilityValue(option: option)
                
                cell.textLabel?.text = option.text
                cell.detailTextLabel?.text = value
                
                if self.poll.publicity == .public {
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                    cell.accessibilityTraits = [.button]
                    cell.accessibilityHint = self.presentationData.strings.VoiceOver_Chat_OpenHint
                } else {
                    cell.accessoryType = .none
                    cell.selectionStyle = .none
                    cell.accessibilityTraits = [.staticText]
                    cell.accessibilityHint = nil
                }
                
                cell.accessibilityLabel = option.text
                cell.accessibilityValue = value
            } else {
                cell.textLabel?.text = ""
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .none
                cell.selectionStyle = .none
                cell.accessibilityTraits = [.staticText]
            }
            
            return cell
            
        case .info:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.numberOfLines = 0
            let text = self.presentationData.strings.CreatePoll_Anonymous
            cell.textLabel?.text = text
            cell.accessoryType = .none
            cell.accessibilityLabel = text
            cell.accessibilityTraits = [.staticText]
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        guard (Section(rawValue: indexPath.section) ?? .summary) == .options else {
            return
        }
        guard self.poll.publicity == .public else {
            return
        }
        guard indexPath.row < self.poll.options.count else {
            return
        }
        let option = self.poll.options[indexPath.row]
        let controller = VoiceOverPollOptionVotersController(
            context: self.context,
            poll: self.poll,
            resultsContext: self.resultsContext,
            optionOpaqueIdentifier: option.opaqueIdentifier,
            optionText: option.text
        )
        controller.navigationPresentation = .modal
        self.push(controller)
    }
}
