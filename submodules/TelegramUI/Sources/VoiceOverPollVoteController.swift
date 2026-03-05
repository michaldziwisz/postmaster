import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramCore
import Postbox

final class VoiceOverPollVoteController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Section: Int, CaseIterable {
        case question
        case options
        case action
    }
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private let messageId: MessageId
    private let poll: TelegramMediaPoll
    
    private let requestSelectOptions: (MessageId, [Data]) -> Void
    private let requestOpenResults: (MessageId, MediaId) -> Void
    
    private let tableView: UITableView
    private let tableNode: ASDisplayNode
    
    private let isMultipleChoice: Bool
    private let canVote: Bool
    
    private var selectedOptionOpaqueIdentifiers: Set<Data> = []
    
    init(
        context: AccountContext,
        messageId: MessageId,
        poll: TelegramMediaPoll,
        requestSelectOptions: @escaping (MessageId, [Data]) -> Void,
        requestOpenResults: @escaping (MessageId, MediaId) -> Void
    ) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.messageId = messageId
        self.poll = poll
        self.requestSelectOptions = requestSelectOptions
        self.requestOpenResults = requestOpenResults
        
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
        
        let hasVoted: Bool = {
            guard let voters = poll.results.voters else {
                return false
            }
            return voters.contains(where: { $0.selected })
        }()
        if poll.isClosed {
            self.canVote = false
        } else if case .quiz = poll.kind, hasVoted {
            self.canVote = false
        } else {
            self.canVote = true
        }
        
        if let voters = poll.results.voters {
            for voter in voters {
                if voter.selected {
                    self.selectedOptionOpaqueIdentifiers.insert(voter.opaqueIdentifier)
                }
            }
        }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title = self.presentationData.strings.AttachmentMenu_Poll
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        let actionTitle = self.actionTitle
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: actionTitle, style: .done, target: self, action: #selector(self.actionPressed))
        self.navigationItem.rightBarButtonItem?.isEnabled = self.isActionEnabled
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
            self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationTheme: presentationData.theme, presentationStrings: presentationData.strings), transition: .immediate)
            self.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
            
            self.title = presentationData.strings.AttachmentMenu_Poll
            self.navigationItem.leftBarButtonItem?.title = presentationData.strings.Common_Cancel
            self.navigationItem.rightBarButtonItem?.title = self.actionTitle
            self.updateActionEnabled()
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
    }
    
    private var actionTitle: String {
        if self.canVote {
            return self.presentationData.strings.MessagePoll_SubmitVote
        } else {
            return self.presentationData.strings.MessagePoll_ViewResults
        }
    }
    
    private var isActionEnabled: Bool {
        if self.canVote {
            return !self.selectedOptionOpaqueIdentifiers.isEmpty
        } else {
            return true
        }
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
    
    @objc private func cancelPressed() {
        self.dismiss()
    }
    
    @objc private func actionPressed() {
        if self.canVote {
            guard self.isActionEnabled else {
                return
            }
            let selected = Array(self.selectedOptionOpaqueIdentifiers)
            self.requestSelectOptions(self.messageId, selected)
            self.dismiss()
        } else {
            self.requestOpenResults(self.messageId, self.poll.pollId)
            self.dismiss()
        }
    }

    private func openResultsPressed() {
        self.requestOpenResults(self.messageId, self.poll.pollId)
        self.dismiss()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.cancelPressed()
        return true
    }
    
    private func updateActionEnabled() {
        let isEnabled = self.isActionEnabled
        self.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
        
        let indexPath = IndexPath(row: 0, section: Section.action.rawValue)
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.textLabel?.text = self.actionTitle
            cell.textLabel?.textColor = isEnabled ? self.presentationData.theme.list.itemAccentColor : self.presentationData.theme.list.itemDisabledTextColor
            cell.accessibilityLabel = self.actionTitle
            cell.accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
        }
    }
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .question {
        case .question:
            return 1
        case .options:
            return self.poll.options.count
        case .action:
            return self.canVote ? 2 : 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .question {
        case .question:
            return self.presentationData.strings.CreatePoll_TextHeader
        case .options:
            return self.presentationData.strings.CreatePoll_OptionsHeader
        case .action:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .question {
        case .question:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = self.poll.text
            return cell
            
        case .options:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.numberOfLines = 0
            if indexPath.row < self.poll.options.count {
                let option = self.poll.options[indexPath.row]
                cell.textLabel?.text = option.text
                if self.selectedOptionOpaqueIdentifiers.contains(option.opaqueIdentifier) {
                    cell.accessoryType = .checkmark
                } else {
                    cell.accessoryType = .none
                }
            } else {
                cell.textLabel?.text = ""
                cell.accessoryType = .none
            }
            cell.selectionStyle = self.canVote ? .default : .none
            return cell
            
        case .action:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .default
            
            let title: String
            let isEnabled: Bool
            if self.canVote && indexPath.row == 1 {
                title = self.presentationData.strings.MessagePoll_ViewResults
                isEnabled = true
            } else {
                title = self.actionTitle
                isEnabled = self.isActionEnabled
                if !isEnabled {
                    cell.selectionStyle = .none
                }
            }

            cell.textLabel?.text = title
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = isEnabled ? self.presentationData.theme.list.itemAccentColor : self.presentationData.theme.list.itemDisabledTextColor

            cell.accessibilityLabel = title
            cell.accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch Section(rawValue: indexPath.section) ?? .question {
        case .question:
            break
        case .options:
            guard self.canVote else {
                return
            }
            guard indexPath.row < self.poll.options.count else {
                return
            }
            let option = self.poll.options[indexPath.row]
            if self.isMultipleChoice {
                if self.selectedOptionOpaqueIdentifiers.contains(option.opaqueIdentifier) {
                    self.selectedOptionOpaqueIdentifiers.remove(option.opaqueIdentifier)
                } else {
                    self.selectedOptionOpaqueIdentifiers.insert(option.opaqueIdentifier)
                }
            } else {
                self.selectedOptionOpaqueIdentifiers.removeAll(keepingCapacity: true)
                self.selectedOptionOpaqueIdentifiers.insert(option.opaqueIdentifier)
            }
            tableView.reloadSections(IndexSet(integer: Section.options.rawValue), with: .none)
            self.updateActionEnabled()
        case .action:
            if self.canVote && indexPath.row == 1 {
                self.openResultsPressed()
            } else {
                self.actionPressed()
            }
        }
    }
}
