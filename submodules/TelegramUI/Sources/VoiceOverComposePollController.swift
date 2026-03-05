import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramCore
import Postbox
import ComposePollUI
import AttachmentUI

final class VoiceOverComposePollController: ViewController, UITableViewDataSource, UITableViewDelegate, AttachmentContainable {
    private enum Section: Int, CaseIterable {
        case question
        case options
        case settings
        case correctAnswer
    }
    
    private enum OptionRow {
        case option(index: Int)
        case add
    }
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private let initialData: ComposePollScreen.InitialData
    private let isQuiz: Bool
    private let completion: (ComposedPoll) -> Void
    
    private let tableView: UITableView
    private let tableNode: ASDisplayNode
    
    private var questionText: String = ""
    private var optionTexts: [String] = ["", ""]
    private var isAnonymous: Bool = true
    private var isMultipleAnswers: Bool = false
    private var selectedCorrectAnswerOriginalIndex: Int?
    
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
        initialData: ComposePollScreen.InitialData,
        isQuiz: Bool,
        completion: @escaping (ComposedPoll) -> Void
    ) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        self.initialData = initialData
        self.isQuiz = isQuiz
        self.completion = completion
        
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        self.tableView = tableView
        self.tableNode = ASDisplayNode(viewBlock: {
            return tableView
        }, didLoad: nil)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationTheme: self.presentationData.theme, presentationStrings: self.presentationData.strings))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
        self.title = isQuiz ? self.presentationData.strings.CreatePoll_QuizTitle : self.presentationData.strings.CreatePoll_Title
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        let doneTitle = self.presentationData.strings.CreatePoll_Create
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
            self.title = self.isQuiz ? presentationData.strings.CreatePoll_QuizTitle : presentationData.strings.CreatePoll_Title
            self.navigationItem.leftBarButtonItem?.title = presentationData.strings.Common_Cancel
            self.navigationItem.rightBarButtonItem?.title = presentationData.strings.CreatePoll_Create
            self.tableView.reloadData()
        })
        
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
            let indexPath = IndexPath(row: 0, section: 0)
            if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                UIAccessibility.post(notification: .screenChanged, argument: cell.textField)
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func cancelPressed() {
        self.dismiss()
    }
    
    @objc private func donePressed() {
        guard let poll = self.buildPoll() else {
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: self.presentationData.strings.CreatePoll_QuizInfo)
            }
            return
        }
        self.completion(poll)
        self.dismiss()
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.cancelPressed()
        return true
    }
    
    // MARK: - UITableViewDataSource / UITableViewDelegate
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.isQuiz {
            return Section.allCases.count
        } else {
            return Section.allCases.filter { $0 != .correctAnswer }.count
        }
    }
    
    private func section(at index: Int) -> Section {
        if self.isQuiz {
            return Section(rawValue: index) ?? .question
        } else {
            // Without quiz, omit `correctAnswer`
            let mapped: [Section] = [.question, .options, .settings]
            return mapped[min(index, mapped.count - 1)]
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        switch self.section(at: sectionIndex) {
        case .question:
            return 1
        case .options:
            return self.optionRowModels().count
        case .settings:
            return self.isQuiz ? 1 : 2
        case .correctAnswer:
            return max(1, self.nonEmptyOptionIndices().count)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        switch self.section(at: sectionIndex) {
        case .question:
            return self.presentationData.strings.CreatePoll_TextHeader
        case .options:
            return self.presentationData.strings.CreatePoll_OptionsHeader
        case .settings:
            return nil
        case .correctAnswer:
            return self.presentationData.strings.CreatePoll_Quiz
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection sectionIndex: Int) -> String? {
        switch self.section(at: sectionIndex) {
        case .options:
            let remaining = max(0, self.initialData.maxPollAnswersCountValue - self.nonEmptyOptionCountUpperBound())
            if remaining == 0 {
                return self.presentationData.strings.CreatePoll_AllOptionsAdded
            }
            return self.presentationData.strings.CreatePoll_OptionCountFooterFormat(Int32(remaining))
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.section(at: indexPath.section) {
        case .question:
            let cell = tableView.dequeueReusableCell(withIdentifier: "textField", for: indexPath) as! VoiceOverFormTextFieldCell
            cell.maxLength = self.initialData.maxPollTextLengthValue
            cell.configure(
                text: self.questionText,
                placeholder: self.presentationData.strings.CreatePoll_TextPlaceholder,
                accessibilityLabel: self.presentationData.strings.CreatePoll_TextHeader,
                isEnabled: true,
                returnKeyType: .next
            )
            cell.onTextChanged = { [weak self] text in
                guard let self else { return }
                self.questionText = text
                self.updateDoneEnabled()
            }
            cell.onReturn = { [weak self] in
                self?.focusFirstOptionFieldIfPossible()
            }
            return cell
            
        case .options:
            let rows = self.optionRowModels()
            let row = rows[indexPath.row]
            switch row {
            case let .option(index):
                let cell = tableView.dequeueReusableCell(withIdentifier: "textField", for: indexPath) as! VoiceOverFormTextFieldCell
                cell.maxLength = self.initialData.maxPollOptionLengthValue
                let placeholder = "\(self.presentationData.strings.CreatePoll_OptionPlaceholder) \(index + 1)"
                cell.configure(
                    text: self.optionTexts[index],
                    placeholder: placeholder,
                    accessibilityLabel: "\(self.presentationData.strings.CreatePoll_OptionPlaceholder) \(index + 1)",
                    isEnabled: true,
                    returnKeyType: (index == self.optionTexts.count - 1 ? .done : .next),
                    autocapitalizationType: .sentences
                )
                cell.onTextChanged = { [weak self] text in
                    guard let self else { return }
                    if index < self.optionTexts.count {
                        self.optionTexts[index] = text
                    }
                    if self.isQuiz {
                        self.reconcileQuizSelection()
                    }
                    self.updateDoneEnabled()
                }
                cell.onReturn = { [weak self] in
                    self?.focusOrAddNextOption(after: index)
                }
                return cell
                
            case .add:
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = self.presentationData.strings.CreatePoll_AddOption
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
            
            if self.isQuiz {
                cell.textLabel?.text = self.presentationData.strings.CreatePoll_Anonymous
                toggle.isOn = self.isAnonymous
                toggle.tag = 1
                toggle.accessibilityLabel = self.presentationData.strings.CreatePoll_Anonymous
            } else {
                if indexPath.row == 0 {
                    cell.textLabel?.text = self.presentationData.strings.CreatePoll_Anonymous
                    toggle.isOn = self.isAnonymous
                    toggle.tag = 1
                    toggle.accessibilityLabel = self.presentationData.strings.CreatePoll_Anonymous
                } else {
                    cell.textLabel?.text = self.presentationData.strings.CreatePoll_MultipleChoice
                    toggle.isOn = self.isMultipleAnswers
                    toggle.tag = 2
                    toggle.accessibilityLabel = self.presentationData.strings.CreatePoll_MultipleChoice
                }
            }
            
            return cell
            
        case .correctAnswer:
            let indices = self.nonEmptyOptionIndices()
            if indices.isEmpty {
                let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
                cell.selectionStyle = .none
                cell.textLabel?.text = self.presentationData.strings.CreatePoll_QuizInfo
                cell.textLabel?.numberOfLines = 0
                return cell
            }
            
            let originalIndex = indices[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel?.text = self.optionTexts[originalIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            if self.selectedCorrectAnswerOriginalIndex == originalIndex {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        
        switch self.section(at: indexPath.section) {
        case .options:
            let rows = self.optionRowModels()
            if indexPath.row < rows.count, case .add = rows[indexPath.row] {
                self.addOptionIfPossible(focusNew: true)
            }
            
        case .correctAnswer:
            let indices = self.nonEmptyOptionIndices()
            guard !indices.isEmpty else {
                return
            }
            let originalIndex = indices[indexPath.row]
            self.selectedCorrectAnswerOriginalIndex = originalIndex
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
            self.updateDoneEnabled()
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard self.section(at: indexPath.section) == .options else {
            return false
        }
        let rows = self.optionRowModels()
        guard indexPath.row < rows.count else {
            return false
        }
        switch rows[indexPath.row] {
        case let .option(index):
            return self.optionTexts.count > 2 && index >= 2
        case .add:
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else {
            return
        }
        let rows = self.optionRowModels()
        guard indexPath.row < rows.count else {
            return
        }
        guard case let .option(index) = rows[indexPath.row] else {
            return
        }
        guard index < self.optionTexts.count else {
            return
        }
        self.optionTexts.remove(at: index)
        if self.isQuiz {
            self.reconcileQuizSelection()
        }
        tableView.reloadData()
        self.updateDoneEnabled()
    }
    
    // MARK: - Helpers
    
    @objc private func settingsSwitchChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 1:
            self.isAnonymous = sender.isOn
        case 2:
            self.isMultipleAnswers = sender.isOn
        default:
            break
        }
        self.updateDoneEnabled()
    }
    
    private func optionRowModels() -> [OptionRow] {
        var rows: [OptionRow] = self.optionTexts.indices.map { .option(index: $0) }
        if self.optionTexts.count < self.initialData.maxPollAnswersCountValue {
            rows.append(.add)
        }
        return rows
    }
    
    private func nonEmptyOptionIndices() -> [Int] {
        return self.optionTexts.indices.filter { index in
            !self.optionTexts[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func nonEmptyOptionCountUpperBound() -> Int {
        // While editing, treat partially-entered options as "used" to avoid confusing footers.
        return self.optionTexts.count
    }
    
    private func reconcileQuizSelection() {
        guard self.isQuiz else {
            return
        }
        if let selected = self.selectedCorrectAnswerOriginalIndex {
            let text = (selected < self.optionTexts.count) ? self.optionTexts[selected].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            if text.isEmpty {
                self.selectedCorrectAnswerOriginalIndex = nil
                self.tableView.reloadData()
            }
        }
    }
    
    private func focusFirstOptionFieldIfPossible() {
        let indexPath = IndexPath(row: 0, section: self.indexOfOptionsSection())
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
    
    private func focusOrAddNextOption(after index: Int) {
        let nextIndex = index + 1
        if nextIndex < self.optionTexts.count {
            let indexPath = IndexPath(row: nextIndex, section: self.indexOfOptionsSection())
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
            self.addOptionIfPossible(focusNew: true)
        }
    }
    
    private func addOptionIfPossible(focusNew: Bool) {
        guard self.optionTexts.count < self.initialData.maxPollAnswersCountValue else {
            return
        }
        self.optionTexts.append("")
        self.tableView.reloadData()
        self.updateDoneEnabled()
        
        guard focusNew else {
            return
        }
        let newIndex = self.optionTexts.count - 1
        let indexPath = IndexPath(row: newIndex, section: self.indexOfOptionsSection())
        self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let cell = self.tableView.cellForRow(at: indexPath) as? VoiceOverFormTextFieldCell {
                cell.textField.becomeFirstResponder()
            }
        }
    }
    
    private func indexOfOptionsSection() -> Int {
        // question + options, and `correctAnswer` may be omitted
        return 1
    }
    
    private func buildPoll() -> ComposedPoll? {
        let questionTrimmed = self.questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !questionTrimmed.isEmpty else {
            return nil
        }
        
        let kind: TelegramMediaPollKind = self.isQuiz ? .quiz : .poll(multipleAnswers: self.isMultipleAnswers)
        let publicity: TelegramMediaPollPublicity = self.isAnonymous ? .anonymous : .public
        
        var options: [TelegramMediaPollOption] = []
        var selectedMappedCorrectAnswer: Data?
        for (originalIndex, text) in self.optionTexts.enumerated() {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue
            }
            let optionData = "\(options.count)".data(using: .utf8)!
            if self.isQuiz, self.selectedCorrectAnswerOriginalIndex == originalIndex {
                selectedMappedCorrectAnswer = optionData
            }
            options.append(TelegramMediaPollOption(text: trimmed, entities: [], opaqueIdentifier: optionData))
        }
        
        guard options.count >= 2 else {
            return nil
        }
        
        var correctAnswers: [Data]?
        if self.isQuiz {
            guard let selectedMappedCorrectAnswer else {
                return nil
            }
            correctAnswers = [selectedMappedCorrectAnswer]
        }
        
        return ComposedPoll(
            publicity: publicity,
            kind: kind,
            text: ComposedPoll.Text(string: questionTrimmed, entities: []),
            options: options,
            correctAnswers: correctAnswers,
            results: TelegramMediaPollResults(voters: nil, totalVoters: nil, recentVoters: [], solution: nil),
            deadlineTimeout: nil,
            usedCustomEmojiFiles: [:]
        )
    }
    
    private func updateDoneEnabled() {
        self.navigationItem.rightBarButtonItem?.isEnabled = (self.buildPoll() != nil)
    }
}
