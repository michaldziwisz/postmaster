import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramCore
import ComposeTodoScreen
import AttachmentUI

final class VoiceOverComposeTodoController: ViewController, UITableViewDataSource, UITableViewDelegate, AttachmentContainable {
    private enum Section: Int, CaseIterable {
        case title
        case tasks
        case settings
        case submit
    }
    
    private enum TaskRow {
        case task(index: Int)
        case add
    }
    
    private struct TaskModel: Equatable {
        var id: Int32
        var text: String
        var isEditable: Bool
        var isExisting: Bool
    }
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private let initialData: ComposeTodoScreen.InitialData
    private let completion: (TelegramMediaTodo) -> Void
    
    private let tableView: UITableView
    private let tableNode: ASDisplayNode
    
    private var titleText: String = ""
    private var tasks: [TaskModel] = []
    private var nextTaskId: Int32 = 1
    
    private var allowOthersToComplete: Bool = true
    private var allowOthersToAppend: Bool = true
    
    // MARK: - AttachmentContainable
    var requestAttachmentMenuExpansion: () -> Void = {}
    var updateNavigationStack: (@escaping ([AttachmentContainable]) -> ([AttachmentContainable], AttachmentMediaPickerContext?)) -> Void = { _ in }
    var parentController: () -> ViewController? = { return nil }
    var updateTabBarAlpha: (CGFloat, ContainedViewLayoutTransition) -> Void = { _, _ in }
    var updateTabBarVisibility: (Bool, ContainedViewLayoutTransition) -> Void = { _, _ in }
    var cancelPanGesture: () -> Void = { }
    var isContainerPanning: () -> Bool = { return false }
    var isContainerExpanded: () -> Bool = { return false }
    var isMinimized: Bool = false
    
    var mediaPickerContext: AttachmentMediaPickerContext? {
        return nil
    }
    
    init(
        context: AccountContext,
        initialData: ComposeTodoScreen.InitialData,
        completion: @escaping (TelegramMediaTodo) -> Void
    ) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.initialData = initialData
        self.completion = completion
        
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        if initialData.appendValue {
            self.title = self.presentationData.strings.CreateTodo_AddTitle
        } else if initialData.existingTodoValue != nil {
            self.title = self.presentationData.strings.CreateTodo_EditTitle
        } else {
            self.title = self.presentationData.strings.CreateTodo_Title
        }
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        let doneTitle = (initialData.existingTodoValue != nil) ? self.presentationData.strings.CreateTodo_Save : self.presentationData.strings.CreateTodo_Send
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: doneTitle, style: .done, target: self, action: #selector(self.donePressed))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).startStrict(next: { [weak self] presentationData in
            guard let self else {
                return
            }
            self.presentationData = presentationData
            self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationTheme: presentationData.theme, presentationStrings: presentationData.strings), transition: .immediate)
            self.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
            
            if self.initialData.appendValue {
                self.title = presentationData.strings.CreateTodo_AddTitle
            } else if self.initialData.existingTodoValue != nil {
                self.title = presentationData.strings.CreateTodo_EditTitle
            } else {
                self.title = presentationData.strings.CreateTodo_Title
            }
            
            self.navigationItem.leftBarButtonItem?.title = presentationData.strings.Common_Cancel
            self.navigationItem.rightBarButtonItem?.title = (self.initialData.existingTodoValue != nil) ? presentationData.strings.CreateTodo_Save : presentationData.strings.CreateTodo_Send
            self.tableView.reloadData()
        })
        
        self.loadInitialState()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.estimatedRowHeight = 56.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.register(VoiceOverFormTextFieldCell.self, forCellReuseIdentifier: "textField")
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if self.initialData.appendValue {
                // In append mode, focus the first empty task field to encourage adding new tasks.
                self.focusFirstEditableTaskFieldIfPossible()
            }
            
            let indexPath = IndexPath(row: 0, section: Section.title.rawValue)
            if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                UIAccessibility.post(notification: .screenChanged, argument: cell.textField)
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
            }
        }
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
    
    // MARK: - Actions
    
    @objc private func cancelPressed() {
        self.dismiss()
    }
    
    @objc private func donePressed() {
        guard let todo = self.buildTodo() else {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: self.presentationData.strings.Attachment_DiscardTodoAlertText)
            }
            return
        }
        self.completion(todo)
        self.dismiss()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.cancelPressed()
        return true
    }
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) ?? .title {
        case .title:
            return 1
        case .tasks:
            return self.taskRowModels().count
        case .settings:
            return 2
        case .submit:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .title {
        case .title:
            return self.presentationData.strings.CreateTodo_TodoTitle
        case .tasks:
            return nil
        case .settings:
            return nil
        case .submit:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch Section(rawValue: section) ?? .title {
        case .tasks:
            let remaining = max(0, self.initialData.maxTodoItemsCountValue - self.tasks.count)
            if remaining == 0 {
                return self.presentationData.strings.CreateTodo_TaskCountLimitReached
            }
            let rawString = self.presentationData.strings.CreateTodo_TaskCountFooterFormat(Int32(remaining))
            return self.remainingCountFooterText(rawString: rawString, count: remaining)
        default:
            return nil
        }
    }
    
    private func remainingCountFooterText(rawString: String, count: Int) -> String {
        guard rawString.contains("{count}") else {
            return rawString
        }
        return rawString.replacingOccurrences(of: "{count}", with: "\(count)")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) ?? .title {
        case .title:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textField", for: indexPath) as! VoiceOverFormTextFieldCell
            cell.maxLength = self.initialData.maxTodoTextLengthValue
            let canEditTitle: Bool = {
                if self.initialData.existingTodoValue != nil, !self.initialData.canEditValue {
                    return false
                }
                return true
            }()
            cell.configure(
                text: self.titleText,
                placeholder: self.presentationData.strings.CreateTodo_TitlePlaceholder,
                accessibilityLabel: self.presentationData.strings.CreateTodo_TodoTitle,
                isEnabled: canEditTitle,
                returnKeyType: .next,
                autocapitalizationType: .sentences
            )
            cell.onTextChanged = { [weak self] text in
                guard let self else { return }
                self.titleText = text
                self.updateDoneEnabled()
            }
            cell.onReturn = { [weak self] in
                self?.focusFirstEditableTaskFieldIfPossible()
            }
            return cell
            
        case .tasks:
            let rows = self.taskRowModels()
            let row = rows[indexPath.row]
            switch row {
            case let .task(index):
                let model = self.tasks[index]
                let cell = tableView.dequeueReusableCell(withIdentifier: "textField", for: indexPath) as! VoiceOverFormTextFieldCell
                cell.maxLength = self.initialData.maxTodoItemLengthValue
                let placeholder: String = {
                    if model.isExisting {
                        return self.presentationData.strings.CreateTodo_TaskPlaceholder
                    } else {
                        return self.presentationData.strings.CreateTodo_AddTaskPlaceholder
                    }
                }()
                cell.configure(
                    text: model.text,
                    placeholder: placeholder,
                    accessibilityLabel: placeholder,
                    isEnabled: model.isEditable,
                    returnKeyType: (index == self.tasks.count - 1 ? .done : .next),
                    autocapitalizationType: .sentences
                )
                cell.onTextChanged = { [weak self] text in
                    guard let self else { return }
                    guard index < self.tasks.count else { return }
                    self.tasks[index].text = text
                    self.updateDoneEnabled()
                }
                cell.onReturn = { [weak self] in
                    self?.focusOrAddNextTask(after: index)
                }
                return cell
                
            case .add:
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = self.presentationData.strings.CreateTodo_AddTaskPlaceholder
                cell.textLabel?.textColor = self.view.tintColor
                cell.accessibilityTraits = [.button]
                cell.selectionStyle = .default
                return cell
            }
            
        case .settings:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .none
            
            let toggle = UISwitch()
            toggle.addTarget(self, action: #selector(self.settingsSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            
            if indexPath.row == 0 {
                cell.textLabel?.text = self.presentationData.strings.CreateTodo_AllowOthersToComplete
                toggle.tag = 1
                toggle.isOn = self.allowOthersToComplete
                toggle.accessibilityLabel = self.presentationData.strings.CreateTodo_AllowOthersToComplete
            } else {
                cell.textLabel?.text = self.presentationData.strings.CreateTodo_AllowOthersToAppend
                toggle.tag = 2
                toggle.isOn = self.allowOthersToAppend
                toggle.isEnabled = self.allowOthersToComplete
                toggle.accessibilityLabel = self.presentationData.strings.CreateTodo_AllowOthersToAppend
            }
            
            return cell
            
        case .submit:
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.selectionStyle = .default
            
            let title = (self.initialData.existingTodoValue != nil) ? self.presentationData.strings.CreateTodo_Save : self.presentationData.strings.CreateTodo_Send
            let isEnabled = (self.buildTodo() != nil)
            
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
        
        switch Section(rawValue: indexPath.section) ?? .title {
        case .tasks:
            let rows = self.taskRowModels()
            if indexPath.row < rows.count, case .add = rows[indexPath.row] {
                self.addTaskIfPossible(focusNew: true)
            }
        case .submit:
            self.donePressed()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard Section(rawValue: indexPath.section) == .tasks else {
            return false
        }
        let rows = self.taskRowModels()
        guard indexPath.row < rows.count else {
            return false
        }
        guard case let .task(index) = rows[indexPath.row] else {
            return false
        }
        let model = self.tasks[index]
        return model.isEditable
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let rows = self.taskRowModels()
        guard indexPath.row < rows.count else {
            return
        }
        guard case let .task(index) = rows[indexPath.row] else {
            return
        }
        guard index < self.tasks.count else {
            return
        }
        guard self.tasks[index].isEditable else {
            return
        }
        self.tasks.remove(at: index)
        tableView.reloadData()
        self.updateDoneEnabled()
    }
    
    // MARK: - Helpers
    
    private func loadInitialState() {
        if let existing = self.initialData.existingTodoValue {
            self.titleText = existing.text
            
            let editableExisting = self.initialData.canEditValue
            self.tasks = existing.items.map { item in
                TaskModel(id: item.id, text: item.text, isEditable: editableExisting, isExisting: true)
            }
            self.nextTaskId = (existing.items.map(\.id).max() ?? 0) + 1
            
            self.allowOthersToComplete = existing.flags.contains(.othersCanComplete)
            self.allowOthersToAppend = existing.flags.contains(.othersCanAppend)
        } else {
            self.titleText = ""
            self.tasks = [TaskModel(id: self.nextTaskId, text: "", isEditable: true, isExisting: false)]
            self.nextTaskId += 1
            self.allowOthersToComplete = true
            self.allowOthersToAppend = true
        }
        
        // If the user is allowed to append (but not edit), ensure at least one empty editable row exists.
        if self.initialData.existingTodoValue != nil, !self.initialData.canEditValue {
            if self.tasks.first(where: { !$0.isExisting && $0.isEditable }) == nil {
                self.addTaskIfPossible(focusNew: false)
            }
        }
        
        self.updateDoneEnabled()
    }
    
    private func taskRowModels() -> [TaskRow] {
        var rows: [TaskRow] = self.tasks.indices.map { .task(index: $0) }
        if self.tasks.count < self.initialData.maxTodoItemsCountValue {
            rows.append(.add)
        }
        return rows
    }
    
    @objc private func settingsSwitchChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 1:
            self.allowOthersToComplete = sender.isOn
            if !self.allowOthersToComplete {
                self.allowOthersToAppend = false
            }
            self.tableView.reloadSections(IndexSet(integer: Section.settings.rawValue), with: .none)
        case 2:
            self.allowOthersToAppend = sender.isOn
        default:
            break
        }
    }
    
    private func focusFirstEditableTaskFieldIfPossible() {
        guard let index = self.tasks.firstIndex(where: { $0.isEditable }) else {
            return
        }
        let indexPath = IndexPath(row: index, section: Section.tasks.rawValue)
        if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
            cell.textField.becomeFirstResponder()
        } else {
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                    cell.textField.becomeFirstResponder()
                }
            }
        }
    }
    
    private func focusOrAddNextTask(after index: Int) {
        let nextIndex = index + 1
        if nextIndex < self.tasks.count {
            let indexPath = IndexPath(row: nextIndex, section: Section.tasks.rawValue)
            if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                cell.textField.becomeFirstResponder()
            } else {
                self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                        cell.textField.becomeFirstResponder()
                    }
                }
            }
        } else {
            self.addTaskIfPossible(focusNew: true)
        }
    }
    
    private func addTaskIfPossible(focusNew: Bool) {
        guard self.tasks.count < self.initialData.maxTodoItemsCountValue else {
            return
        }
        self.tasks.append(TaskModel(id: self.nextTaskId, text: "", isEditable: true, isExisting: false))
        self.nextTaskId += 1
        self.tableView.reloadData()
        self.updateDoneEnabled()
        
        guard focusNew else {
            return
        }
        let indexPath = IndexPath(row: self.tasks.count - 1, section: Section.tasks.rawValue)
        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                cell.textField.becomeFirstResponder()
            }
        }
    }
    
    private func buildTodo() -> TelegramMediaTodo? {
        let titleTrimmed = self.titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrimmed.isEmpty else {
            return nil
        }
        
        var mappedItems: [TelegramMediaTodo.Item] = []
        mappedItems.reserveCapacity(self.tasks.count)
        for task in self.tasks {
            let trimmed = task.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue
            }
            mappedItems.append(TelegramMediaTodo.Item(text: trimmed, entities: [], id: task.id))
        }
        guard !mappedItems.isEmpty else {
            return nil
        }
        
        // If we can't edit the original todo, ensure we are actually appending something.
        if let existing = self.initialData.existingTodoValue, !self.initialData.canEditValue {
            if mappedItems.count <= existing.items.count {
                return nil
            }
        }
        
        var flags: TelegramMediaTodo.Flags = []
        if self.allowOthersToComplete {
            flags.insert(.othersCanComplete)
            if self.allowOthersToAppend {
                flags.insert(.othersCanAppend)
            }
        }
        
        return TelegramMediaTodo(flags: flags, text: titleTrimmed, textEntities: [], items: mappedItems)
    }
    
    private func updateDoneEnabled() {
        let isEnabled = (self.buildTodo() != nil)
        self.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
        
        let indexPath = IndexPath(row: 0, section: Section.submit.rawValue)
        if let cell = self.tableView.cellForRow(at: indexPath) {
            let title = (self.initialData.existingTodoValue != nil) ? self.presentationData.strings.CreateTodo_Save : self.presentationData.strings.CreateTodo_Send
            cell.textLabel?.text = title
            cell.textLabel?.textColor = isEnabled ? self.presentationData.theme.list.itemAccentColor : self.presentationData.theme.list.itemDisabledTextColor
            cell.accessibilityLabel = title
            cell.accessibilityTraits = isEnabled ? [.button] : [.button, .notEnabled]
        }
    }
}
