import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramCore
import Postbox

final class VoiceOverPollOptionVotersController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Section: Int, CaseIterable {
        case voters
        case loadMore
    }
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private let poll: TelegramMediaPoll
    private let resultsContext: PollResultsContext
    private let optionOpaqueIdentifier: Data
    private let optionText: String
    
    private var optionState: PollResultsOptionState?
    private var optionStateDisposable: Disposable?
    
    private let tableView: UITableView
    private let tableNode: ASDisplayNode
    
    init(
        context: AccountContext,
        poll: TelegramMediaPoll,
        resultsContext: PollResultsContext,
        optionOpaqueIdentifier: Data,
        optionText: String
    ) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.poll = poll
        self.resultsContext = resultsContext
        self.optionOpaqueIdentifier = optionOpaqueIdentifier
        self.optionText = optionText
        
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title = self.optionText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
            self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationTheme: presentationData.theme, presentationStrings: presentationData.strings), transition: .immediate)
            self.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
            self.updateLeftBarButtonItem()
            self.tableView.reloadData()
        })
        
        self.optionStateDisposable = (resultsContext.state
        |> deliverOnMainQueue).startStrict(next: { [weak self] state in
            guard let self else {
                return
            }
            self.optionState = state.options[self.optionOpaqueIdentifier]
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
        self.optionStateDisposable?.dispose()
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
        if let navigationController = self.navigationController, navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss()
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.closePressed()
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateLeftBarButtonItem()
    }

    private func updateLeftBarButtonItem() {
        if let navigationController = self.navigationController, navigationController.viewControllers.first !== self {
            self.navigationItem.leftBarButtonItem = nil
        } else if self.navigationItem.leftBarButtonItem == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: self, action: #selector(self.closePressed))
        } else {
            self.navigationItem.leftBarButtonItem?.title = self.presentationData.strings.Common_Back
        }
    }
    
    private func titleForLoadMoreRow(optionState: PollResultsOptionState) -> (title: String, isEnabled: Bool) {
        if optionState.isLoadingMore {
            return (self.presentationData.strings.Channel_NotificationLoading, false)
        }
        let remaining = max(0, optionState.count - optionState.peers.count)
        if remaining > 0 {
            return (self.presentationData.strings.PollResults_ShowMore(Int32(remaining)), true)
        } else {
            return (self.presentationData.strings.MessagePoll_NoVotes, false)
        }
    }
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .voters {
        case .voters:
            let count = self.optionState?.peers.count ?? 0
            return max(1, count)
        case .loadMore:
            guard let optionState = self.optionState else {
                return 0
            }
            return (optionState.canLoadMore || optionState.isLoadingMore) ? 1 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .voters {
        case .voters:
            switch self.poll.publicity {
            case .anonymous:
                return self.presentationData.strings.CreatePoll_Anonymous
            case .public:
                return self.presentationData.strings.PollResults_Title
            }
        case .loadMore:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .voters {
        case .voters:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.numberOfLines = 0
            
            if let optionState = self.optionState, !optionState.peers.isEmpty, indexPath.row < optionState.peers.count {
                let peer = optionState.peers[indexPath.row]
                if let peerValue = peer.peer {
                    let title = EnginePeer(peerValue).displayTitle(strings: self.presentationData.strings, displayOrder: self.presentationData.nameDisplayOrder)
                    cell.textLabel?.text = title
                    cell.accessoryType = .disclosureIndicator
                    cell.accessibilityLabel = title
                    cell.accessibilityTraits = [.button]
                } else {
                    let title = self.presentationData.strings.User_DeletedAccount
                    cell.textLabel?.text = title
                    cell.accessoryType = .none
                    cell.accessibilityLabel = title
                    cell.accessibilityTraits = [.staticText]
                }
            } else {
                let title: String
                switch self.poll.kind {
                case .poll:
                    title = self.presentationData.strings.MessagePoll_NoVotes
                case .quiz:
                    title = self.presentationData.strings.MessagePoll_QuizNoUsers
                }
                cell.textLabel?.text = title
                cell.accessoryType = .none
                cell.accessibilityLabel = title
                cell.accessibilityTraits = [.staticText]
            }
            
            return cell
            
        case .loadMore:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.textAlignment = .center
            
            if let optionState = self.optionState {
                let (title, isEnabled) = self.titleForLoadMoreRow(optionState: optionState)
                cell.textLabel?.text = title
                cell.textLabel?.textColor = isEnabled ? self.presentationData.theme.list.itemAccentColor : self.presentationData.theme.list.itemDisabledTextColor
                cell.accessibilityLabel = title
                cell.accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
                cell.selectionStyle = isEnabled ? .default : .none
            } else {
                cell.textLabel?.text = ""
                cell.textLabel?.textColor = self.presentationData.theme.list.itemPrimaryTextColor
                cell.accessibilityTraits = [.staticText]
                cell.selectionStyle = .none
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch Section(rawValue: indexPath.section) ?? .voters {
        case .voters:
            guard let optionState = self.optionState, indexPath.row < optionState.peers.count else {
                return
            }
            let peer = optionState.peers[indexPath.row]
            guard let peerValue = peer.peer else {
                return
            }
            let enginePeer = EnginePeer(peerValue)
            if let controller = self.context.sharedContext.makePeerInfoController(context: self.context, updatedPresentationData: nil, peer: enginePeer._asPeer(), mode: .generic, avatarInitiallyExpanded: false, fromChat: true, requestsContext: nil) {
                self.push(controller)
            }
        case .loadMore:
            guard let optionState = self.optionState else {
                return
            }
            guard optionState.canLoadMore, !optionState.isLoadingMore else {
                return
            }
            self.resultsContext.loadMore(optionOpaqueIdentifier: self.optionOpaqueIdentifier)
        }
    }
}
