import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import ContextUI
import TelegramPresentationData

final class VoiceOverContextMenuController: ViewController, ContextControllerProtocol, UIAdaptivePresentationControllerDelegate {
    private struct MenuLevel {
        let items: Signal<ContextController.Items, NoError>
        let title: String?
        var resolvedItems: ContextController.Items?
    }
    
    private struct ActionEntry {
        let title: String
        let style: UIAlertAction.Style
        let isEnabled: Bool
        let perform: () -> Void
    }
    
    private let presentationData: PresentationData
    private let sourceRectInWindow: CGRect?
    private weak var sourceView: UIView?
    private weak var focusReturnView: UIView?
    
    private var menuLevels: [MenuLevel]
    private var itemsDisposable: Disposable?
    private var currentAlertController: UIAlertController?
    private var pendingAfterAlertDismissal: (() -> Void)?
    private var hasPresentedInitialMenu = false
    private var didRunDismissed = false
    private var currentInvokedActionTitle: String?
    
    var useComplexItemsTransitionAnimation: Bool = false
    var immediateItemsTransitionAnimation: Bool = false
    var getOverlayViews: (() -> [UIView])?
    var dismissed: (() -> Void)?
    
    init(
        presentationData: PresentationData,
        items: Signal<ContextController.Items, NoError>,
        sourceView: UIView?,
        sourceRectInWindow: CGRect?,
        focusReturnView: UIView?
    ) {
        self.presentationData = presentationData
        self.sourceView = sourceView
        self.sourceRectInWindow = sourceRectInWindow
        self.focusReturnView = focusReturnView
        self.menuLevels = [
            MenuLevel(items: items, title: nil, resolvedItems: nil)
        ]
        
        super.init(navigationBarPresentationData: nil)
        
        self.blocksBackgroundWhenInOverlay = true
        self.acceptsFocusWhenInOverlay = true
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.itemsDisposable?.dispose()
    }
    
    override func loadDisplayNode() {
        self.displayNode = ASDisplayNode()
        self.displayNode.backgroundColor = .clear
        self.displayNode.isAccessibilityElement = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard !self.hasPresentedInitialMenu else {
            return
        }
        self.hasPresentedInitialMenu = true
        self.presentCurrentMenu(animated: false)
    }
    
    override func accessibilityPerformEscape() -> Bool {
        self.dismiss(completion: nil)
        return true
    }
    
    func getActionsMinHeight() -> ContextController.ActionsHeight? {
        return nil
    }
    
    func setItems(_ items: Signal<ContextController.Items, NoError>, minHeight: ContextController.ActionsHeight?, animated: Bool) {
        self.replaceCurrentItems(with: items, animated: animated)
    }
    
    func setItems(_ items: Signal<ContextController.Items, NoError>, minHeight: ContextController.ActionsHeight?, previousActionsTransition: ContextController.PreviousActionsTransition) {
        self.replaceCurrentItems(with: items, animated: true)
    }
    
    func pushItems(items: Signal<ContextController.Items, NoError>) {
        let title = self.currentInvokedActionTitle
        self.scheduleAfterCurrentAlertDismissal { [weak self] in
            guard let self else {
                return
            }
            self.menuLevels.append(MenuLevel(items: items, title: title, resolvedItems: nil))
            self.presentCurrentMenu(animated: false)
        }
    }
    
    func popItems() {
        self.scheduleAfterCurrentAlertDismissal { [weak self] in
            guard let self else {
                return
            }
            guard self.menuLevels.count > 1 else {
                self.dismiss(completion: nil)
                return
            }
            self.runDismissed(for: self.menuLevels.removeLast())
            self.presentCurrentMenu(animated: false)
        }
    }
    
    override func dismiss(completion: (() -> Void)? = nil) {
        self.dismiss(result: .default, completion: completion)
    }
    
    func dismiss(result: ContextMenuActionResult, completion: (() -> Void)?) {
        self.scheduleAfterCurrentAlertDismissal { [weak self] in
            self?.dismissSelf(completion: completion)
        }
    }
    
    private func replaceCurrentItems(with items: Signal<ContextController.Items, NoError>, animated: Bool) {
        self.scheduleAfterCurrentAlertDismissal { [weak self] in
            guard let self, !self.menuLevels.isEmpty else {
                return
            }
            self.runDismissed(for: self.menuLevels.removeLast())
            self.menuLevels.append(MenuLevel(items: items, title: nil, resolvedItems: nil))
            self.presentCurrentMenu(animated: animated)
        }
    }
    
    private func presentCurrentMenu(animated: Bool) {
        guard let level = self.menuLevels.last else {
            self.dismissSelf(completion: nil)
            return
        }
        
        self.itemsDisposable?.dispose()
        self.itemsDisposable = (level.items
        |> take(1)
        |> deliverOnMainQueue).startStrict(next: { [weak self] items in
            guard let self, !self.menuLevels.isEmpty else {
                return
            }
            self.menuLevels[self.menuLevels.count - 1].resolvedItems = items
            self.presentAlert(for: items, title: level.title, animated: animated)
        })
    }
    
    private func presentAlert(for items: ContextController.Items, title: String?, animated: Bool) {
        let configuration = self.buildConfiguration(for: items)
        let alertStyle: UIAlertController.Style = configuration.actions.isEmpty ? .alert : .actionSheet
        let alert = UIAlertController(
            title: self.normalizedText(title),
            message: configuration.messageLines.isEmpty ? nil : configuration.messageLines.joined(separator: "\n\n"),
            preferredStyle: alertStyle
        )
        
        for actionEntry in configuration.actions {
            let action = UIAlertAction(title: actionEntry.title, style: actionEntry.style) { [weak self] _ in
                self?.currentInvokedActionTitle = actionEntry.title
                self?.pendingAfterAlertDismissal = nil
                actionEntry.perform()
                if self?.pendingAfterAlertDismissal == nil {
                    self?.pendingAfterAlertDismissal = { [weak self] in
                        self?.dismissSelf(completion: nil)
                    }
                }
            }
            action.isEnabled = actionEntry.isEnabled
            alert.addAction(action)
        }
        
        if self.menuLevels.count > 1 && !configuration.hasExplicitBackAction {
            alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Back, style: .default) { [weak self] _ in
                self?.popItems()
            })
        }
        
        alert.addAction(UIAlertAction(title: self.presentationData.strings.Common_Cancel, style: .cancel) { [weak self] _ in
            self?.dismiss(completion: nil)
        })
        
        alert.presentationController?.delegate = self
        self.configurePopover(for: alert)
        
        self.currentAlertController = alert
        self.present(alert, animated: animated)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard presentationController.presentedViewController === self.currentAlertController else {
            return
        }
        self.currentAlertController = nil
        
        if let pendingAfterAlertDismissal = self.pendingAfterAlertDismissal {
            self.pendingAfterAlertDismissal = nil
            pendingAfterAlertDismissal()
        } else {
            self.dismissSelf(completion: nil)
        }
    }
    
    private func configurePopover(for alert: UIAlertController) {
        guard let popoverPresentationController = alert.popoverPresentationController else {
            return
        }
        
        popoverPresentationController.sourceView = self.view
        if let anchorRect = self.anchorRectInSelfView() {
            popoverPresentationController.sourceRect = anchorRect
        } else {
            popoverPresentationController.sourceRect = CGRect(
                x: self.view.bounds.midX,
                y: self.view.bounds.midY,
                width: 1.0,
                height: 1.0
            )
        }
    }
    
    private func anchorRectInSelfView() -> CGRect? {
        if let sourceView = self.sourceView, sourceView.window != nil {
            return self.view.convert(sourceView.bounds, from: sourceView)
        }
        if let sourceRectInWindow = self.sourceRectInWindow, let window = self.view.window {
            return self.view.convert(sourceRectInWindow, from: window)
        }
        return nil
    }
    
    private func buildConfiguration(for items: ContextController.Items) -> (actions: [ActionEntry], messageLines: [String], hasExplicitBackAction: Bool) {
        let flattenedItems: [ContextMenuItem]
        switch items.content {
        case let .list(itemList):
            flattenedItems = itemList
        case let .twoLists(primary, secondary):
            flattenedItems = primary + secondary
        case .custom:
            return (
                actions: [],
                messageLines: ["This menu section is not available yet with VoiceOver."],
                hasExplicitBackAction: false
            )
        }
        
        var actions: [ActionEntry] = []
        var messageLines: [String] = []
        var hasExplicitBackAction = false
        
        for item in flattenedItems {
            switch item {
            case let .action(actionItem):
                let title = self.displayText(for: actionItem)
                if title == self.presentationData.strings.Common_Back {
                    hasExplicitBackAction = true
                }
                
                if let action = actionItem.action {
                    let style: UIAlertAction.Style = actionItem.textColor == .destructive ? .destructive : .default
                    actions.append(ActionEntry(title: title, style: style, isEnabled: actionItem.textColor != .disabled) { [weak self] in
                        guard let self else {
                            return
                        }
                        action(
                            ContextMenuActionItem.Action(
                                controller: self,
                                dismissWithResult: { [weak self] result in
                                    self?.dismiss(result: result, completion: nil)
                                },
                                updateAction: { _, _ in }
                            )
                        )
                    })
                } else {
                    messageLines.append(title)
                }
            case let .custom(customItem, _):
                let customNode = customItem.node(
                    presentationData: self.presentationData,
                    getController: { [weak self] in
                        return self
                    },
                    actionSelected: { [weak self] result in
                        self?.dismiss(result: result, completion: nil)
                    }
                )
                let typeName = String(describing: type(of: customNode))
                let title = self.displayText(for: customNode) ?? self.fallbackText(forCustomNodeType: typeName)
                if title == self.presentationData.strings.Common_Back {
                    hasExplicitBackAction = true
                }
                
                if customNode.canBeHighlighted() {
                    actions.append(ActionEntry(title: title, style: .default, isEnabled: true) {
                        customNode.performAction()
                    })
                } else {
                    messageLines.append(title)
                }
            case .separator:
                continue
            }
        }
        
        return (actions, messageLines, hasExplicitBackAction)
    }
    
    private func displayText(for actionItem: ContextMenuActionItem) -> String {
        var components: [String] = []
        let primaryText = self.normalizedText(actionItem.text)
        if let primaryText {
            components.append(primaryText)
        }
        
        switch actionItem.textLayout {
        case .singleLine, .twoLinesMax, .multiline:
            break
        case let .secondLineWithValue(value):
            if let value = self.normalizedText(value) {
                components.append(value)
            }
        case let .secondLineWithAttributedValue(value):
            if let value = self.normalizedText(value.string) {
                components.append(value)
            }
        }
        
        if let badge = actionItem.badge, let value = self.normalizedText(badge.value), !components.contains(value) {
            components.append(value)
        }
        
        if components.isEmpty {
            return "Menu Item"
        } else {
            return components.joined(separator: "\n")
        }
    }
    
    private func displayText(for customNode: ContextMenuCustomNode) -> String? {
        let _ = customNode.view
        
        var texts: [String] = []
        self.collectTextValues(from: customNode, into: &texts)
        if texts.isEmpty {
            return nil
        }
        
        var unique: [String] = []
        for text in texts {
            if !unique.contains(text) {
                unique.append(text)
            }
        }
        return unique.joined(separator: "\n")
    }
    
    private func fallbackText(forCustomNodeType typeName: String) -> String {
        if typeName.contains("ChatDeleteMessageContextItemNode") {
            return self.presentationData.strings.Conversation_ContextMenuDelete
        } else if typeName.contains("ChatReadReportContextItemNode") {
            return self.presentationData.strings.Conversation_ContextMenuSeen(0)
        } else if typeName.contains("ChatMessageAuthorContextItemNode") {
            return self.presentationData.strings.Chat_ContextMenu_AuthorInfo("").string
        } else if typeName.contains("ChatRateTranscriptionContextItemNode") {
            return self.presentationData.strings.Chat_AudioTranscriptionRateAction
        } else {
            return "Menu Item"
        }
    }
    
    private func collectTextValues(from value: Any, into results: inout [String], depth: Int = 0) {
        guard depth < 4 else {
            return
        }
        
        if let attributedText = value as? NSAttributedString, let normalized = self.normalizedText(attributedText.string) {
            results.append(normalized)
            return
        }
        if let string = value as? String, let normalized = self.normalizedText(string) {
            results.append(normalized)
            return
        }
        
        let mirror = Mirror(reflecting: value)
        for child in mirror.children {
            let label = child.label?.lowercased() ?? ""
            if label.contains("placeholder") {
                continue
            }
            if label.contains("textnode") || label.contains("statusnode") || label.contains("badgetext") || label.contains("text") || depth > 0 {
                self.collectTextValues(from: child.value, into: &results, depth: depth + 1)
            }
        }
    }
    
    private func scheduleAfterCurrentAlertDismissal(_ completion: @escaping () -> Void) {
        if let currentAlertController = self.currentAlertController {
            self.pendingAfterAlertDismissal = completion
            currentAlertController.dismiss(animated: true)
        } else {
            Queue.mainQueue().async(completion)
        }
    }
    
    private func dismissSelf(completion: (() -> Void)?) {
        while let lastLevel = self.menuLevels.popLast() {
            self.runDismissed(for: lastLevel)
        }
        
        let finalDismissed = self.dismissed
        super.dismiss(completion: nil)
        Queue.mainQueue().after(0.0) { [weak self] in
            guard let self else {
                completion?()
                finalDismissed?()
                return
            }
            if !self.didRunDismissed {
                self.didRunDismissed = true
                finalDismissed?()
            }
            completion?()
            if UIAccessibility.isVoiceOverRunning, let focusReturnView = self.focusReturnView, focusReturnView.window != nil {
                UIAccessibility.post(notification: .screenChanged, argument: focusReturnView)
            }
        }
    }
    
    private func runDismissed(for level: MenuLevel) {
        level.resolvedItems?.dismissed?()
    }
    
    private func normalizedText(_ text: String?) -> String? {
        guard let text else {
            return nil
        }
        let normalized = text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }
}
