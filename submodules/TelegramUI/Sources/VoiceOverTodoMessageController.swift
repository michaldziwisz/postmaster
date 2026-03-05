import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramCore
import Postbox

final class VoiceOverTodoMessageController: ViewController, UITableViewDataSource, UITableViewDelegate {
    private enum Section: Int, CaseIterable {
        case tasks
    }
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private let message: Message
    private let todo: TelegramMediaTodo
    private let requestToggleItem: (MessageId, Int32, Bool) -> Void
    private let displayUnavailable: (MessageId) -> Void
    
    private let tableView: UITableView
    private let tableNode: ASDisplayNode
    
    private var completedIds: Set<Int32> = []
    private let canToggle: Bool
    
    init(
        context: AccountContext,
        message: Message,
        todo: TelegramMediaTodo,
        requestToggleItem: @escaping (MessageId, Int32, Bool) -> Void,
        displayUnavailable: @escaping (MessageId) -> Void
    ) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.message = message
        self.todo = todo
        self.requestToggleItem = requestToggleItem
        self.displayUnavailable = displayUnavailable
        
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)
        
        self.completedIds = Set(todo.completions.map(\.id))
        
        let isIncoming = message.effectivelyIncoming(context.account.peerId)
        if message.forwardInfo != nil {
            self.canToggle = false
        } else if !context.isPremium {
            self.canToggle = false
        } else if isIncoming && !todo.flags.contains(.othersCanComplete) {
            self.canToggle = false
        } else {
            self.canToggle = true
        }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        let titleText = todo.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.title = titleText.isEmpty ? self.presentationData.strings.Chat_Todo_Message_Title : titleText
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
            self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationTheme: presentationData.theme, presentationStrings: presentationData.strings), transition: .immediate)
            self.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
            let titleText = self.todo.text.trimmingCharacters(in: .whitespacesAndNewlines)
            self.title = titleText.isEmpty ? presentationData.strings.Chat_Todo_Message_Title : titleText
            self.updateLeftBarButtonItem()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateLeftBarButtonItem()
    }
    
    // MARK: - Actions
    
    @objc private func cancelPressed() {
        if let navigationController = self.navigationController, navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss()
        }
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.cancelPressed()
        return true
    }

    private func updateLeftBarButtonItem() {
        if let navigationController = self.navigationController, navigationController.viewControllers.first !== self {
            self.navigationItem.leftBarButtonItem = nil
        } else if self.navigationItem.leftBarButtonItem == nil {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
        } else {
            self.navigationItem.leftBarButtonItem?.title = self.presentationData.strings.Common_Cancel
        }
    }
    
    @objc private func taskSwitchChanged(_ sender: UISwitch) {
        let itemId = Int32(clamping: sender.tag)
        let shouldBeOn = self.completedIds.contains(itemId)
        
        if !self.canToggle {
            sender.setOn(shouldBeOn, animated: false)
            self.displayUnavailable(self.message.id)
            return
        }
        
        let newValue = sender.isOn
        if newValue {
            self.completedIds.insert(itemId)
        } else {
            self.completedIds.remove(itemId)
        }
        self.requestToggleItem(self.message.id, itemId, newValue)
    }
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .tasks {
        case .tasks:
            return self.todo.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .tasks {
        case .tasks:
            return self.presentationData.strings.Chat_Todo_ContextMenu_SectionTask
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        
        if indexPath.row < self.todo.items.count {
            let item = self.todo.items[indexPath.row]
            cell.textLabel?.text = item.text
            
            let toggle = UISwitch()
            toggle.tag = Int(item.id)
            let isCompleted = self.completedIds.contains(item.id)
            toggle.isOn = isCompleted
            toggle.addTarget(self, action: #selector(self.taskSwitchChanged(_:)), for: .valueChanged)
            toggle.accessibilityLabel = item.text
            cell.accessoryView = toggle
            
            // Avoid double-voicing the row + the toggle. Let the switch be the only focusable element.
            cell.isAccessibilityElement = false
        } else {
            cell.textLabel?.text = ""
            cell.accessoryView = nil
            cell.isAccessibilityElement = true
        }
        
        return cell
    }
}
