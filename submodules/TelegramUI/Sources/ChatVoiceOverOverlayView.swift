import Foundation
import UIKit
import ObjectiveC
import AppBundle
import Postbox
import TelegramCore
import TelegramPresentationData
import ChatPresentationInterfaceState
import TelegramStringFormatting
import ChatHistoryEntry
import TelegramUIPreferences

private final class ChatVoiceOverOverlayScrollBarProxyAccessibilityElement: UIAccessibilityElement {
    weak var tableView: ChatVoiceOverOverlayTableView?
    
    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    init(tableView: ChatVoiceOverOverlayTableView) {
        self.tableView = tableView
        super.init(accessibilityContainer: tableView)
        self.isAccessibilityElement = true
        self.accessibilityTraits = [.adjustable]
    }
    
    override var accessibilityLabel: String? {
        get {
            // VoiceOver-only control. Keep the label simple and stable.
            return "Pasek przewijania"
        }
        set {
        }
    }
    
    override var accessibilityValue: String? {
        get {
            guard let tableView else {
                return nil
            }

            guard let progress = tableView.voiceOverScrollbarProxyProgressFraction() else {
                return nil
            }
            return Self.percentFormatter.string(from: NSNumber(value: Double(progress))) ?? "\(Int((progress * 100.0).rounded()))%"
        }
        set {
        }
    }
    
    override var accessibilityFrameInContainerSpace: CGRect {
        get {
            guard let tableView else {
                return .zero
            }
            let bounds = tableView.bounds
            let width = ChatVoiceOverOverlayTableView.voiceOverScrollbarGutterWidth
            return CGRect(x: bounds.maxX - width, y: bounds.minY, width: width, height: bounds.height)
        }
        set {
        }
    }
    
    override var accessibilityFrame: CGRect {
        get {
            guard let tableView else {
                return .zero
            }
            let rect = self.accessibilityFrameInContainerSpace
            return tableView.convert(rect, to: nil)
        }
        set {
        }
    }
    
    override func accessibilityIncrement() {
        // For a scrollbar, "increment" (VO swipe up) should move towards older messages (up).
        self.scrollByPage(towardTop: true)
    }
    
    override func accessibilityDecrement() {
        // For a scrollbar, "decrement" (VO swipe down) should move towards newer messages (down).
        self.scrollByPage(towardTop: false)
    }
    
    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        self.tableView?.noteVoiceOverScrollbarProxyFocused()
    }
    
    override func accessibilityElementDidLoseFocus() {
        super.accessibilityElementDidLoseFocus()
        self.tableView?.scheduleClearVoiceOverScrollbarProxyFromAccessibilityOrder()
    }
    
    private func scrollByPage(towardTop: Bool) {
        guard let tableView else {
            return
        }
        tableView.voiceOverScrollbarProxyScrollByStep(towardTop: towardTop)
    }
    
    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            guard let tableView, let overlay = tableView.overlayForAccessibilityElements else {
                return nil
            }
            
            let strings = overlay.voiceOverPresentationStrings()
            var actions: [UIAccessibilityCustomAction] = []
            
            if overlay.actions.openProfile != nil {
                actions.append(UIAccessibilityCustomAction(name: strings.KeyCommand_ChatInfo, actionHandler: { [weak overlay] _ in
                    overlay?.actions.openProfile?()
                    return true
                }))
            }
            
            if overlay.voiceOverCanTriggerLoadEarlierFromProxy() {
                let title = overlay.voiceOverLoadEarlierActionTitle()
                actions.append(UIAccessibilityCustomAction(name: title, actionHandler: { [weak overlay] _ in
                    overlay?.voiceOverTriggerLoadEarlierFromProxy()
                    return true
                }))
            }
            
            return actions.isEmpty ? nil : actions
        }
        set {
        }
    }
}

private final class ChatVoiceOverOverlayTableView: UITableView {
    var onDidPerformAccessibilityScroll: (() -> Void)?
    weak var overlayForAccessibilityElements: ChatVoiceOverOverlayView?
    fileprivate static let voiceOverScrollbarGutterWidth: CGFloat = 22.0

    private var voiceOverScrollbarProxyElement: ChatVoiceOverOverlayScrollBarProxyAccessibilityElement?
    private var voiceOverScrollbarProxyLastHitTestPoint: CGPoint?
    private var voiceOverScrollbarProxyLastInsertionIndex: Int?
    private var isVoiceOverScrollbarProxyInAccessibilityOrder = false

    fileprivate func noteVoiceOverScrollbarProxyFocused() {
        self.isVoiceOverScrollbarProxyInAccessibilityOrder = true
    }
    
    fileprivate func clearVoiceOverScrollbarProxyFromAccessibilityOrder() {
        self.isVoiceOverScrollbarProxyInAccessibilityOrder = false
        self.voiceOverScrollbarProxyLastInsertionIndex = nil
        self.voiceOverScrollbarProxyLastHitTestPoint = nil
    }

    fileprivate func scheduleClearVoiceOverScrollbarProxyFromAccessibilityOrder() {
        DispatchQueue.main.async { [weak self] in
            self?.clearVoiceOverScrollbarProxyFromAccessibilityOrder()
        }
    }
    
    private func isInVoiceOverScrollbarGutter(_ point: CGPoint) -> Bool {
        let bounds = self.bounds
        return point.x >= bounds.maxX - Self.voiceOverScrollbarGutterWidth
    }

    private func normalizeAccessibilityHitTestPointToLocal(_ point: CGPoint) -> CGPoint {
        if self.bounds.contains(point) {
            return point
        }
        let converted = self.convert(point, from: nil)
        if self.bounds.contains(converted) {
            return converted
        }
        return point
    }
    
    private func currentVoiceOverScrollbarProxyInsertionIndex(overlay: ChatVoiceOverOverlayView, baseCount: Int) -> Int? {
        guard self.isVoiceOverScrollbarProxyInAccessibilityOrder, baseCount > 0 else {
            return nil
        }
        let point = self.voiceOverScrollbarProxyLastHitTestPoint ?? CGPoint(x: self.bounds.maxX - 1.0, y: self.bounds.midY)
        
        let hasLoadEarlierRow: Bool = {
            guard let first = overlay.tableAccessibilityElement(at: 0) as? ChatVoiceOverOverlayRowAccessibilityElement else {
                return false
            }
            if case .loadEarlier = first.kind {
                return true
            }
            return false
        }()
        let minContentIndex = hasLoadEarlierRow ? 1 : 0
        
        let visibleSorted = self.indexPathsForVisibleRows?.sorted()
        let anchorPoint = CGPoint(x: self.bounds.midX, y: point.y)
        let anchorIndexPath: IndexPath? = {
            if let indexPath = self.indexPathForRow(at: anchorPoint) {
                return indexPath
            }
            guard let visibleSorted, !visibleSorted.isEmpty else {
                return nil
            }
            var best: IndexPath?
            var bestDistance: CGFloat = .greatestFiniteMagnitude
            for indexPath in visibleSorted {
                let rect = self.rectForRow(at: indexPath)
                let dy: CGFloat
                if anchorPoint.y < rect.minY {
                    dy = rect.minY - anchorPoint.y
                } else if anchorPoint.y > rect.maxY {
                    dy = anchorPoint.y - rect.maxY
                } else {
                    dy = 0.0
                }
                if dy < bestDistance {
                    bestDistance = dy
                    best = indexPath
                }
            }
            return best ?? visibleSorted[visibleSorted.count / 2]
        }()

        // Place the proxy BETWEEN two VISIBLE message rows so that swipe navigation doesn't leave the list.
        let rawAnchorRow = max(0, min(baseCount - 1, anchorIndexPath?.row ?? self.voiceOverScrollbarProxyLastInsertionIndex ?? 0))
        let firstVisibleRow = visibleSorted?.first?.row ?? rawAnchorRow
        let lastVisibleRow = visibleSorted?.last?.row ?? rawAnchorRow
        let visibleSafeInsertionRow: Int
        if rawAnchorRow <= firstVisibleRow {
            visibleSafeInsertionRow = min(lastVisibleRow, firstVisibleRow + 1)
        } else if rawAnchorRow >= lastVisibleRow {
            visibleSafeInsertionRow = lastVisibleRow
        } else {
            visibleSafeInsertionRow = rawAnchorRow
        }

        // Place the proxy BETWEEN two message rows so that both swipe directions go to messages.
        let minInsertionIndex = minContentIndex + 1
        let maxInsertionIndex = baseCount - 1
        if minInsertionIndex <= maxInsertionIndex {
            let index = min(max(visibleSafeInsertionRow, minInsertionIndex), maxInsertionIndex)
            self.voiceOverScrollbarProxyLastInsertionIndex = index
            return index
        } else {
            // Not enough rows to place it safely between two message elements.
            let index = baseCount
            self.voiceOverScrollbarProxyLastInsertionIndex = index
            return index
        }
    }
    
    private func canScrollVertically(_ direction: UIAccessibilityScrollDirection) -> Bool {
        let minOffset = -self.adjustedContentInset.top
        let maxOffset = max(minOffset, self.contentSize.height - self.bounds.height + self.adjustedContentInset.bottom)
        let y = self.contentOffset.y
        switch direction {
        case .up:
            return y > minOffset + 1.0
        case .down:
            return y < maxOffset - 1.0
        default:
            return false
        }
    }
    
    private func performManualPageScroll(direction: UIAccessibilityScrollDirection) -> Bool {
        guard direction == .up || direction == .down else {
            return false
        }
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
        let range = maxOffset - minOffset
        if range > 1.0 {
            let progress = (self.contentOffset.y - minOffset) / range
            let clamped = max(0.0, min(1.0, progress))
            let percent = Int((clamped * 100.0).rounded())
            UIAccessibility.post(notification: .pageScrolled, argument: "\(percent)%")
        } else {
            UIAccessibility.post(notification: .pageScrolled, argument: nil)
        }
        return true
    }
    
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        // UIKit first (best for native VO behavior).
        if super.accessibilityScroll(direction) {
            self.onDidPerformAccessibilityScroll?()
            return true
        }

        // Last resort: page scroll for actual scroll requests.
        let verticalDirection: UIAccessibilityScrollDirection
        switch direction {
        case .previous, .left:
            verticalDirection = .up
        case .next, .right:
            verticalDirection = .down
        default:
            verticalDirection = direction
        }
        if self.canScrollVertically(verticalDirection), self.performManualPageScroll(direction: verticalDirection) {
            self.onDidPerformAccessibilityScroll?()
            return true
        }

        return false
    }

    override var accessibilityElements: [Any]? {
        get {
            guard UIAccessibility.isVoiceOverRunning else {
                return nil
            }
            guard let overlay = self.overlayForAccessibilityElements else {
                return nil
            }
            var elements = overlay.tableAccessibilityElements
            let baseCount = elements.count
            guard let proxy = self.voiceOverScrollbarProxyElement, let index = self.currentVoiceOverScrollbarProxyInsertionIndex(overlay: overlay, baseCount: baseCount) else {
                return elements
            }
            if index >= 0, index <= baseCount {
                elements.insert(proxy, at: index)
            }
            return elements
        }
        set {
        }
    }

    override func accessibilityElementCount() -> Int {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.accessibilityElementCount()
        }
        guard let overlay = self.overlayForAccessibilityElements else {
            return 0
        }
        let baseCount = overlay.tableAccessibilityElementCount
        guard self.voiceOverScrollbarProxyElement != nil, self.currentVoiceOverScrollbarProxyInsertionIndex(overlay: overlay, baseCount: baseCount) != nil else {
            return baseCount
        }
        return baseCount + 1
    }

    override func accessibilityElement(at index: Int) -> Any? {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.accessibilityElement(at: index)
        }
        guard let overlay = self.overlayForAccessibilityElements else {
            return nil
        }
        let baseCount = overlay.tableAccessibilityElementCount
        if let proxy = self.voiceOverScrollbarProxyElement, let insertionIndex = self.currentVoiceOverScrollbarProxyInsertionIndex(overlay: overlay, baseCount: baseCount) {
            if index == insertionIndex {
                return proxy
            } else if index < insertionIndex {
                return overlay.tableAccessibilityElement(at: index)
            } else {
                return overlay.tableAccessibilityElement(at: index - 1)
            }
        } else {
            return overlay.tableAccessibilityElement(at: index)
        }
    }

    override func index(ofAccessibilityElement element: Any) -> Int {
        if UIAccessibility.isVoiceOverRunning, let overlay = self.overlayForAccessibilityElements {
            let baseCount = overlay.tableAccessibilityElementCount
            let insertionIndex = self.currentVoiceOverScrollbarProxyInsertionIndex(overlay: overlay, baseCount: baseCount)
            if let proxy = self.voiceOverScrollbarProxyElement, let insertionIndex {
                let object = element as AnyObject
                if proxy === object {
                    return insertionIndex
                }
            }

            let baseIndex = overlay.tableAccessibilityIndex(of: element)
            if baseIndex != NSNotFound {
                if let insertionIndex, baseIndex >= insertionIndex {
                    return baseIndex + 1
                } else {
                    return baseIndex
                }
            }
        }
        return super.index(ofAccessibilityElement: element)
    }

    private func voiceOverCustomHitTest(_ point: CGPoint) -> Any? {
        let localPoint = self.normalizeAccessibilityHitTestPointToLocal(point)
        return self.voiceOverCustomHitTestInContainerSpace(localPoint)
    }
    
    private func voiceOverCustomHitTestInContainerSpace(_ point: CGPoint) -> Any? {
        guard UIAccessibility.isVoiceOverRunning, let overlay = self.overlayForAccessibilityElements else {
            return nil
        }

        // Provide a VoiceOver-only scrollbar proxy in the right gutter.
        if self.isInVoiceOverScrollbarGutter(point) {
            self.voiceOverScrollbarProxyLastHitTestPoint = point
            self.isVoiceOverScrollbarProxyInAccessibilityOrder = true
            let element: ChatVoiceOverOverlayScrollBarProxyAccessibilityElement
            if let current = self.voiceOverScrollbarProxyElement {
                element = current
            } else {
                element = ChatVoiceOverOverlayScrollBarProxyAccessibilityElement(tableView: self)
                self.voiceOverScrollbarProxyElement = element
            }
            return element
        }

        if let indexPath = self.indexPathForRow(at: point), let element = overlay.accessibilityElement(at: indexPath) {
            return element
        }

        // If the user explores between rows, fall back to the nearest visible row.
        guard let visibleIndexPaths = self.indexPathsForVisibleRows, !visibleIndexPaths.isEmpty else {
            return nil
        }
        var nearestIndexPath: IndexPath?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude
        for indexPath in visibleIndexPaths {
            let rect = self.rectForRow(at: indexPath)
            let dy: CGFloat
            if point.y < rect.minY {
                dy = rect.minY - point.y
            } else if point.y > rect.maxY {
                dy = point.y - rect.maxY
            } else {
                dy = 0.0
            }
            if dy < nearestDistance {
                nearestDistance = dy
                nearestIndexPath = indexPath
            }
        }
        if let nearestIndexPath, let element = overlay.accessibilityElement(at: nearestIndexPath) {
            return element
        }

        return nil
    }

    fileprivate func voiceOverAccessibilityElementFromContainerPoint(_ point: CGPoint) -> Any? {
        return self.voiceOverCustomHitTestInContainerSpace(point)
    }

    // iOS 17 and earlier.
    @objc(accessibilityHitTest:)
    func accessibilityHitTest(_ point: CGPoint) -> Any? {
        if let element = self.voiceOverCustomHitTest(point) {
            return element
        }
        if #available(iOS 18.0, *) {
            return super.accessibilityHitTest(point, event: nil)
        }

        let selector = NSSelectorFromString("accessibilityHitTest:")
        let baseMethod =
            class_getInstanceMethod(UITableView.self, selector) ??
            class_getInstanceMethod(UIScrollView.self, selector) ??
            class_getInstanceMethod(UIView.self, selector)
        guard let baseMethod else {
            return nil
        }
        typealias HitTestIMP = @convention(c) (AnyObject, Selector, CGPoint) -> AnyObject?
        let imp = method_getImplementation(baseMethod)
        let fn = unsafeBitCast(imp, to: HitTestIMP.self)
        return fn(self, selector, point)
    }

    // iOS 18+ (new SDK signature).
    @available(iOS 18.0, *)
    public override func accessibilityHitTest(_ point: CGPoint, event: UIEvent?) -> Any? {
        if let element = self.voiceOverCustomHitTest(point) {
            return element
        }
        return super.accessibilityHitTest(point, event: event)
    }

    fileprivate func voiceOverScrollbarProxyScrollByStep(towardTop: Bool) {
        let minOffset = -self.adjustedContentInset.top
        let maxOffset = max(minOffset, self.contentSize.height - self.bounds.height + self.adjustedContentInset.bottom)
        let range = maxOffset - minOffset
        guard range > 1.0 else {
            return
        }

        let pageHeight = max(1.0, self.bounds.height - self.adjustedContentInset.top - self.adjustedContentInset.bottom)
        let pageDelta = pageHeight * 0.85
        let percentDelta = range * 0.05
        let maxDelta = pageHeight * 4.0
        let delta = min(max(pageDelta, percentDelta), maxDelta)

        let sign: CGFloat = towardTop ? -1.0 : 1.0
        let targetY = min(max(self.contentOffset.y + (delta * sign), minOffset), maxOffset)
        if abs(targetY - self.contentOffset.y) < 1.0 {
            return
        }
        self.setContentOffset(CGPoint(x: self.contentOffset.x, y: targetY), animated: false)
    }

    fileprivate func voiceOverScrollbarProxyProgressFraction() -> CGFloat? {
        let minOffset = -self.adjustedContentInset.top
        let maxOffset = max(minOffset, self.contentSize.height - self.bounds.height + self.adjustedContentInset.bottom)
        let range = maxOffset - minOffset
        guard range > 1.0 else {
            return nil
        }

        let raw = (self.contentOffset.y - minOffset) / range
        return max(0.0, min(1.0, raw))
    }
}

private final class ChatVoiceOverOverlayCell: UITableViewCell {
    var onDidBecomeFocused: (() -> Void)?
    
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

    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        self.onDidBecomeFocused?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.onDidBecomeFocused = nil
    }
}

private final class ChatVoiceOverOverlayRowAccessibilityElement: UIAccessibilityElement {
    enum Kind: Equatable {
        case loadEarlier
        case row(stableId: UInt64)
    }
    
    weak var overlay: ChatVoiceOverOverlayView?
    let kind: Kind
    
    init(container: AnyObject, overlay: ChatVoiceOverOverlayView, kind: Kind) {
        self.overlay = overlay
        self.kind = kind
        super.init(accessibilityContainer: container)
        self.isAccessibilityElement = true
    }
    
    override var accessibilityFrameInContainerSpace: CGRect {
        get {
            return self.overlay?.accessibilityFrameInContainerSpace(for: self) ?? .zero
        }
        set {
        }
    }

    override var accessibilityFrame: CGRect {
        get {
            return self.overlay?.accessibilityFrameInScreenSpace(for: self) ?? .zero
        }
        set {
        }
    }
    
    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        self.overlay?.voiceOverElementDidBecomeFocused(self)
    }
    
    override func accessibilityActivate() -> Bool {
        return self.overlay?.activateVoiceOverElement(self) ?? false
    }

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        return self.overlay?.voiceOverAccessibilityScroll(direction) ?? false
    }
    
    override var accessibilityLabel: String? {
        get {
            return self.overlay?.voiceOverAccessibilityLabel(for: self)
        }
        set {
        }
    }
    
    override var accessibilityHint: String? {
        get {
            return self.overlay?.voiceOverAccessibilityHint(for: self)
        }
        set {
        }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return self.overlay?.voiceOverAccessibilityTraits(for: self) ?? super.accessibilityTraits
        }
        set {
        }
    }
    
    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return self.overlay?.voiceOverAccessibilityCustomActions(for: self)
        }
        set {
        }
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
    private var composerHeightConstraint: NSLayoutConstraint?
    private var keyboardObservers: [NSObjectProtocol] = []
    
    private var interfaceState: ChatPresentationInterfaceState?
    private var rows: [Row] = []
    private var rowIndexByStableId: [UInt64: Int] = [:]

    private var cachedAccessibilityElements: [Any] = []
    private var needsAccessibilityElementsRebuild = true
    private var isRebuildingAccessibilityElements = false

    private var loadEarlierAccessibilityElement: ChatVoiceOverOverlayRowAccessibilityElement?
    private var rowAccessibilityElementsByStableId: [UInt64: ChatVoiceOverOverlayRowAccessibilityElement] = [:]
    private var lastFocusedTableIndexPathForScroll: IndexPath?

    private var canLoadEarlierHistory = false
    private var isLoadingEarlierHistory = false
    private var didReceiveLoadEarlierState = false
    
    private var shouldShowLoadEarlierRow: Bool {
        return self.didReceiveLoadEarlierState || self.canLoadEarlierHistory || self.isLoadEarlierInProgress
    }
    
    private var isLoadEarlierInProgress: Bool {
        return self.isWaitingForLoadEarlier || self.isLoadingEarlierHistory
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
    
    private enum LoadEarlierInitiationFocus {
        case loadEarlierRow
        case message(ScrollAnchor)
    }
    private var loadEarlierScrollAnchor: ScrollAnchor?
    private var lastUserScrollAnchor: ScrollAnchor?
    private var loadEarlierInitiationFocus: LoadEarlierInitiationFocus?

    private var shouldFollowLatest: Bool = true

    private var isComposerEnabled: Bool = true

    private var lastVoiceOverNavigationTimestamp: CFTimeInterval = 0.0
    
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

    // Prefer UIKit's native accessibility tree for the chat screen (top bar + table view cells + composer).
    // This enables the system VoiceOver scrollbar and 3-finger scroll gestures without custom hit-testing.
    public override var accessibilityElements: [Any]? {
        get {
            return nil
        }
        set {
        }
    }
    
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
        self.tableView.overlayForAccessibilityElements = self
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.estimatedRowHeight = 96.0
        self.tableView.estimatedSectionHeaderHeight = 0.0
        self.tableView.estimatedSectionFooterHeight = 0.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.alwaysBounceVertical = true
        self.tableView.isAccessibilityElement = false
        if #available(iOS 11.0, *) {
            self.tableView.accessibilityContainerType = .list
        }
        // Let UIKit manage the accessibility navigation order for a list.
        // Explicitly overriding grouping/navigation style can prevent VoiceOver
        // from auto-scrolling to offscreen rows during swipe navigation.
        self.tableView.accessibilityNavigationStyle = .automatic
        self.tableView.shouldGroupAccessibilityChildren = false
        // Use native UITableView cell accessibility for messages to get:
        // - the system VoiceOver scrollbar (localized, correct behavior),
        // - working 3-finger scroll gestures,
        // - predictable hit-testing during touch exploration.
        self.tableView.accessibilityElementsHidden = false
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
        self.inputTextView.isScrollEnabled = true
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
        let composerHeight = self.composerView.heightAnchor.constraint(equalToConstant: 64.0)
        self.composerHeightConstraint = composerHeight
        
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
            composerHeight,
            
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
            self.inputTextView.heightAnchor.constraint(lessThanOrEqualToConstant: 120.0),
            
            self.tableView.topAnchor.constraint(equalTo: self.topBarView.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.composerView.topAnchor)
        ])
        
        self.composerView.setContentHuggingPriority(.required, for: .vertical)
        self.composerView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.tableView.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.tableView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

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
        self.invalidateAccessibilityElements()
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
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ChatVoiceOverOverlayCell {
                    self.configureLoadEarlierCell(cell)
                } else {
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            } else {
                self.tableView.reloadData()
            }
            self.tableView.layoutIfNeeded()
        }
        
        self.invalidateAccessibilityElements()
    }

    private func schedulePendingEntriesApplyIfNeeded() {
        guard self.pendingEntries != nil else {
            return
        }
        guard self.pendingEntriesWorkItem == nil else {
            return
        }
        
        let delay: TimeInterval
        if self.tableView.isDragging || self.tableView.isDecelerating {
            delay = 0.2
        } else if UIAccessibility.isVoiceOverRunning, !self.isLoadEarlierInProgress, self.isVoiceOverNavigationInProgress() {
            delay = 0.25
        } else {
            delay = 0.05
        }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            self.pendingEntriesWorkItem = nil
            
            if self.tableView.isDragging || self.tableView.isDecelerating {
                self.schedulePendingEntriesApplyIfNeeded()
                return
            }
            if UIAccessibility.isVoiceOverRunning, !self.isLoadEarlierInProgress, self.isVoiceOverNavigationInProgress() {
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
        if let cell = cell as? ChatVoiceOverOverlayCell {
            self.configureCell(cell, at: indexPath)
        }
        return cell
    }

    private func configureCell(_ cell: ChatVoiceOverOverlayCell, at indexPath: IndexPath) {
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.isAccessibilityElement = false
        
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption1)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.isAccessibilityElement = false
        
        cell.selectionStyle = .none
        // The chat rows are exposed as custom `UIAccessibilityElement`s owned by the table view.
        // Keep real table cells out of the accessibility tree to avoid duplicate elements and
        // to keep swipe navigation stable while still enabling the system VO scrollbar.
        if UIAccessibility.isVoiceOverRunning {
            cell.isAccessibilityElement = false
            cell.accessibilityElementsHidden = true
        } else {
            cell.isAccessibilityElement = true
            cell.accessibilityElementsHidden = false
        }
        cell.accessibilityCustomActions = nil

        if self.shouldShowLoadEarlierRow, indexPath.row == 0 {
            self.configureLoadEarlierCell(cell)

            #if DEBUG
            let debugTitle = "Speak debug state"
            var actions = cell.accessibilityCustomActions ?? []
            actions.append(UIAccessibilityCustomAction(name: debugTitle, actionHandler: { [weak self] _ in
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
            }))
            cell.accessibilityCustomActions = actions
            #endif

            return
        }

        let rowIndex = indexPath.row - self.loadEarlierRowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = ""
            cell.accessibilityHint = nil
            cell.accessibilityTraits = [.staticText]
            cell.onDidBecomeFocused = nil
            return
        }

        guard let state = self.interfaceState else {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = nil
            cell.accessibilityLabel = ""
            cell.accessibilityHint = nil
            cell.accessibilityTraits = [.staticText]
            cell.onDidBecomeFocused = nil
            return
        }

        let row = self.rows[rowIndex]
        let resolved = self.resolveRow(row, state: state)

        cell.backgroundColor = state.theme.list.plainBackgroundColor
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
        if case let .message(message) = row.kind {
            cell.onDidBecomeFocused = { [weak self] in
                guard let self else {
                    return
                }
                self.noteVoiceOverNavigationActivity()
                self.captureLastUserScrollAnchor()
            }

            if self.isMessageActivatable(message) {
                cell.selectionStyle = .default
            }

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
        } else {
            cell.onDidBecomeFocused = { [weak self] in
                guard let self else {
                    return
                }
                self.noteVoiceOverNavigationActivity()
                self.captureLastUserScrollAnchor()
            }
        }
    }

    private func configureLoadEarlierCell(_ cell: ChatVoiceOverOverlayCell) {
        cell.onDidBecomeFocused = { [weak self] in
            guard let self else {
                return
            }
            self.noteVoiceOverNavigationActivity()
            self.captureLastUserScrollAnchor()
        }

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
            self.loadEarlierInitiationFocus = .loadEarlierRow
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !self.isNearTop() {
            self.loadEarlierNoProgressCount = 0
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === self.tableView else {
            return
        }
        if !decelerate {
            self.captureLastUserScrollAnchor()
            self.applyPendingEntriesIfPossible()
            self.maybeEnsureAtLatestIfNeeded()
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.captureLastUserScrollAnchor()
        self.applyPendingEntriesIfPossible()
        self.maybeEnsureAtLatestIfNeeded()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.captureLastUserScrollAnchor()
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
        if UIAccessibility.isVoiceOverRunning, self.loadEarlierInitiationFocus == nil, let anchor = self.focusedMessageScrollAnchor() ?? self.currentScrollAnchor() {
            self.loadEarlierInitiationFocus = .message(anchor)
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

    public override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        return self.tableView.accessibilityScroll(direction)
    }
    
    // MARK: - Helpers

    fileprivate func noteVoiceOverNavigationActivity() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        self.lastVoiceOverNavigationTimestamp = CACurrentMediaTime()
    }

    private func updateRowIndexByStableId() {
        self.rowIndexByStableId.removeAll(keepingCapacity: true)
        self.rowIndexByStableId.reserveCapacity(self.rows.count)
        for (index, row) in self.rows.enumerated() {
            self.rowIndexByStableId[row.stableId] = index
        }
    }

    private func invalidateAccessibilityElements() {
        self.needsAccessibilityElementsRebuild = true
        self.cachedAccessibilityElements = []
    }

    fileprivate var tableAccessibilityElements: [Any] {
        self.rebuildAccessibilityElementsIfNeeded()
        return self.cachedAccessibilityElements
    }

    fileprivate var tableAccessibilityElementCount: Int {
        self.rebuildAccessibilityElementsIfNeeded()
        return self.cachedAccessibilityElements.count
    }

    fileprivate func tableAccessibilityElement(at index: Int) -> Any? {
        self.rebuildAccessibilityElementsIfNeeded()
        guard index >= 0, index < self.cachedAccessibilityElements.count else {
            return nil
        }
        return self.cachedAccessibilityElements[index]
    }

    fileprivate func tableAccessibilityIndex(of element: Any) -> Int {
        guard let element = element as? ChatVoiceOverOverlayRowAccessibilityElement else {
            return NSNotFound
        }
        guard element.overlay === self else {
            return NSNotFound
        }
        switch element.kind {
        case .loadEarlier:
            return self.shouldShowLoadEarlierRow ? 0 : NSNotFound
        case let .row(stableId):
            guard let rowIndex = self.rowIndexByStableId[stableId] else {
                return NSNotFound
            }
            return rowIndex + self.loadEarlierRowOffset
        }
    }

    private func rebuildAccessibilityElementsIfNeeded() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.needsAccessibilityElementsRebuild else {
            return
        }
        guard !self.isRebuildingAccessibilityElements else {
            return
        }
        self.isRebuildingAccessibilityElements = true
        defer {
            self.isRebuildingAccessibilityElements = false
        }

        self.needsAccessibilityElementsRebuild = false

        var elements: [Any] = []
        elements.reserveCapacity(self.rows.count + (self.shouldShowLoadEarlierRow ? 1 : 0))

        if self.shouldShowLoadEarlierRow {
            let element: ChatVoiceOverOverlayRowAccessibilityElement
            if let current = self.loadEarlierAccessibilityElement {
                element = current
            } else {
                element = ChatVoiceOverOverlayRowAccessibilityElement(container: self.tableView, overlay: self, kind: .loadEarlier)
                self.loadEarlierAccessibilityElement = element
            }
            element.overlay = self
            elements.append(element)
        } else {
            self.loadEarlierAccessibilityElement = nil
        }

        var newElementsByStableId: [UInt64: ChatVoiceOverOverlayRowAccessibilityElement] = [:]
        newElementsByStableId.reserveCapacity(self.rows.count)
        for row in self.rows {
            let element = self.rowAccessibilityElementsByStableId[row.stableId] ?? ChatVoiceOverOverlayRowAccessibilityElement(container: self.tableView, overlay: self, kind: .row(stableId: row.stableId))
            element.overlay = self
            newElementsByStableId[row.stableId] = element
            elements.append(element)
        }
        self.rowAccessibilityElementsByStableId = newElementsByStableId

        self.cachedAccessibilityElements = elements
    }

    fileprivate func accessibilityElement(at indexPath: IndexPath) -> ChatVoiceOverOverlayRowAccessibilityElement? {
        self.rebuildAccessibilityElementsIfNeeded()
        guard indexPath.section == 0 else {
            return nil
        }
        if self.shouldShowLoadEarlierRow, indexPath.row == 0 {
            return self.loadEarlierAccessibilityElement
        }
        let rowIndex = indexPath.row - self.loadEarlierRowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            return nil
        }
        let stableId = self.rows[rowIndex].stableId
        return self.rowAccessibilityElementsByStableId[stableId]
    }

    fileprivate func voiceOverAccessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        return self.tableView.accessibilityScroll(direction)
    }

    private func nearestVisibleIndexPath(to tablePoint: CGPoint) -> IndexPath? {
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows, !visibleIndexPaths.isEmpty else {
            return nil
        }
        var nearestIndexPath: IndexPath?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude
        for indexPath in visibleIndexPaths {
            let rect = self.tableView.rectForRow(at: indexPath)
            let dy: CGFloat
            if tablePoint.y < rect.minY {
                dy = rect.minY - tablePoint.y
            } else if tablePoint.y > rect.maxY {
                dy = tablePoint.y - rect.maxY
            } else {
                dy = 0.0
            }
            if dy < nearestDistance {
                nearestDistance = dy
                nearestIndexPath = indexPath
            }
        }
        return nearestIndexPath
    }

    // iOS 17 and earlier.
    @objc(accessibilityHitTest:)
    func accessibilityHitTest(_ point: CGPoint) -> Any? {
        if #available(iOS 18.0, *) {
            if let element = self.voiceOverCustomHitTest(point) {
                return element
            }
            return super.accessibilityHitTest(point, event: nil)
        }
        
        if let element = self.voiceOverCustomHitTest(point) {
            return element
        }

        // iOS 17: call UIView's `accessibilityHitTest:` implementation to allow UIKit to
        // expose system-provided elements like the native VO scrollbar.
        let selector = NSSelectorFromString("accessibilityHitTest:")
        guard let method = class_getInstanceMethod(UIView.self, selector) else {
            return nil
        }
        typealias HitTestIMP = @convention(c) (AnyObject, Selector, CGPoint) -> AnyObject?
        let imp = method_getImplementation(method)
        let fn = unsafeBitCast(imp, to: HitTestIMP.self)
        return fn(self, selector, point)
    }

    // iOS 18+ (new SDK signature).
    @available(iOS 18.0, *)
    public override func accessibilityHitTest(_ point: CGPoint, event: UIEvent?) -> Any? {
        if let element = self.voiceOverCustomHitTest(point) {
            return element
        }
        return super.accessibilityHitTest(point, event: event)
    }

    private func voiceOverCustomHitTest(_ point: CGPoint) -> Any? {
        guard UIAccessibility.isVoiceOverRunning else {
            return nil
        }

        let pointInTableFromSelf = self.tableView.convert(point, from: self)
        if self.tableView.bounds.contains(pointInTableFromSelf) {
            return self.tableView.voiceOverAccessibilityElementFromContainerPoint(pointInTableFromSelf)
        }

        let pointInTableFromScreen = self.tableView.convert(point, from: nil)
        if self.tableView.bounds.contains(pointInTableFromScreen) {
            return self.tableView.voiceOverAccessibilityElementFromContainerPoint(pointInTableFromScreen)
        }

        return nil
    }

    fileprivate func voiceOverPresentationStrings() -> PresentationStrings {
        return self.interfaceState?.strings ?? defaultPresentationStrings
    }

    fileprivate func voiceOverLoadEarlierActionTitle() -> String {
        let bundle = getAppBundle()
        let titleKey = "VoiceOver.Chat.LoadEarlier"
        let titleFallback = "Load older messages"
        return bundle.localizedString(forKey: titleKey, value: titleFallback, table: nil)
    }

    fileprivate func voiceOverCanTriggerLoadEarlierFromProxy() -> Bool {
        return self.canLoadEarlierHistory && !self.isLoadEarlierInProgress
    }

    fileprivate func voiceOverTriggerLoadEarlierFromProxy() {
        guard !self.isLoadEarlierInProgress else {
            return
        }

        if self.loadEarlierInitiationFocus == nil, let anchor = self.lastUserScrollAnchor ?? self.currentScrollAnchor() {
            self.loadEarlierInitiationFocus = .message(anchor)
        }
        self.triggerLoadEarlierRequest()
    }

    private func indexPath(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> IndexPath? {
        switch element.kind {
        case .loadEarlier:
            guard self.shouldShowLoadEarlierRow else {
                return nil
            }
            return IndexPath(row: 0, section: 0)
        case let .row(stableId):
            guard let rowIndex = self.rowIndexByStableId[stableId] else {
                return nil
            }
            let tableRow = rowIndex + self.loadEarlierRowOffset
            return IndexPath(row: tableRow, section: 0)
        }
    }

    private func row(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> Row? {
        switch element.kind {
        case .loadEarlier:
            return nil
        case let .row(stableId):
            guard let rowIndex = self.rowIndexByStableId[stableId], rowIndex >= 0, rowIndex < self.rows.count else {
                return nil
            }
            return self.rows[rowIndex]
        }
    }

    fileprivate func accessibilityFrameInContainerSpace(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> CGRect {
        guard let indexPath = self.indexPath(for: element) else {
            return .zero
        }
        guard indexPath.section == 0, indexPath.row >= 0, indexPath.row < self.tableView.numberOfRows(inSection: 0) else {
            return .zero
        }
        return self.tableView.rectForRow(at: indexPath)
    }

    fileprivate func accessibilityFrameInScreenSpace(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> CGRect {
        guard let indexPath = self.indexPath(for: element) else {
            return .zero
        }
        guard indexPath.section == 0, indexPath.row >= 0, indexPath.row < self.tableView.numberOfRows(inSection: 0) else {
            return .zero
        }
        let rect = self.tableView.rectForRow(at: indexPath)
        return self.tableView.convert(rect, to: nil)
    }

    fileprivate func voiceOverElementDidBecomeFocused(_ element: ChatVoiceOverOverlayRowAccessibilityElement) {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        self.noteVoiceOverNavigationActivity()

        guard let indexPath = self.indexPath(for: element) else {
            return
        }

        let wasVisible: Bool = self.tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false
        if !wasVisible {
            let scrollPosition: UITableView.ScrollPosition
            if let previous = self.lastFocusedTableIndexPathForScroll {
                if indexPath.row < previous.row {
                    scrollPosition = .top
                } else if indexPath.row > previous.row {
                    scrollPosition = .bottom
                } else {
                    scrollPosition = .middle
                }
            } else {
                scrollPosition = .middle
            }

            UIView.performWithoutAnimation {
                self.tableView.scrollToRow(at: indexPath, at: scrollPosition, animated: false)
                self.tableView.layoutIfNeeded()
            }
        }

        self.lastFocusedTableIndexPathForScroll = indexPath
        self.captureLastUserScrollAnchor()

        if !wasVisible {
            DispatchQueue.main.async { [weak element] in
                guard let element, UIAccessibility.isVoiceOverRunning else {
                    return
                }
                UIAccessibility.post(notification: .layoutChanged, argument: element)
            }
        }
    }

    fileprivate func activateVoiceOverElement(_ element: ChatVoiceOverOverlayRowAccessibilityElement) -> Bool {
        switch element.kind {
        case .loadEarlier:
            guard self.canLoadEarlierHistory, !self.isLoadEarlierInProgress else {
                return false
            }
            self.loadEarlierInitiationFocus = .loadEarlierRow
            self.triggerLoadEarlierRequest()
            return true
        case .row:
            guard let row = self.row(for: element) else {
                return false
            }
            guard case let .message(message) = row.kind else {
                return false
            }
            guard self.isMessageActivatable(message) else {
                return false
            }
            self.actions.activateMessage?(message)
            return true
        }
    }

    fileprivate func voiceOverAccessibilityLabel(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> String {
        switch element.kind {
        case .loadEarlier:
            let bundle = getAppBundle()
            if self.isLoadEarlierInProgress {
                return bundle.localizedString(forKey: "VoiceOver.Chat.LoadEarlier.Loading", value: "Loading older messages", table: nil)
            } else if self.canLoadEarlierHistory {
                return bundle.localizedString(forKey: "VoiceOver.Chat.LoadEarlier", value: "Load older messages", table: nil)
            } else {
                return bundle.localizedString(forKey: "VoiceOver.Chat.LoadEarlier.None", value: "No older messages", table: nil)
            }
        case .row:
            guard let row = self.row(for: element), let state = self.interfaceState else {
                return ""
            }
            let resolved = self.resolveRow(row, state: state)
            return resolved.accessibilityLabel
        }
    }

    fileprivate func voiceOverAccessibilityHint(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> String? {
        switch element.kind {
        case .loadEarlier:
            return nil
        case .row:
            guard let row = self.row(for: element), let state = self.interfaceState else {
                return nil
            }
            let resolved = self.resolveRow(row, state: state)
            return resolved.hint
        }
    }

    fileprivate func voiceOverAccessibilityTraits(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> UIAccessibilityTraits {
        switch element.kind {
        case .loadEarlier:
            if self.isLoadEarlierInProgress {
                return [.button, .notEnabled]
            } else if self.canLoadEarlierHistory {
                return [.button]
            } else {
                return [.staticText]
            }
        case .row:
            guard let row = self.row(for: element), let state = self.interfaceState else {
                return [.staticText]
            }
            let resolved = self.resolveRow(row, state: state)
            return resolved.traits
        }
    }

    fileprivate func voiceOverAccessibilityCustomActions(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> [UIAccessibilityCustomAction]? {
        guard let state = self.interfaceState else {
            return nil
        }
        switch element.kind {
        case .loadEarlier:
            #if DEBUG
            let debugTitle = "Speak debug state"
            return [
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
            #else
            return nil
            #endif
        case .row:
            guard let row = self.row(for: element) else {
                return nil
            }
            guard case let .message(message) = row.kind else {
                return nil
            }

            var customActions: [UIAccessibilityCustomAction] = []
            let moreTitle = state.strings.Conversation_ContextMenuMore
            customActions.append(UIAccessibilityCustomAction(name: moreTitle, actionHandler: { [weak self] _ in
                guard let self else {
                    return false
                }
                guard let indexPath = self.indexPath(for: element) else {
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

            return customActions.isEmpty ? nil : customActions
        }
    }
    
    private func isVoiceOverNavigationInProgress(graceInterval: CFTimeInterval = 0.8) -> Bool {
        guard UIAccessibility.isVoiceOverRunning else {
            return false
        }
        let now = CACurrentMediaTime()
        guard now - self.lastVoiceOverNavigationTimestamp < graceInterval else {
            return false
        }
        return self.focusedTableViewIndexPath() != nil
    }
    
    private func applyPendingEntriesIfPossible(force: Bool = false) {
        guard let entries = self.pendingEntries else {
            return
        }
        if !force {
            if self.tableView.isDragging || self.tableView.isDecelerating {
                return
            }
            if UIAccessibility.isVoiceOverRunning, !self.isLoadEarlierInProgress, self.isVoiceOverNavigationInProgress() {
                return
            }
        }
        self.pendingEntries = nil
        self.applyEntries(entries)
    }
    
    private func applyEntries(_ entries: [ChatHistoryEntry]) {
        let incomingRows = self.makeRows(from: entries)
        let newRows = self.mergeRows(existing: self.rows, incoming: incomingRows)
        
        let previousWasAtBottom = self.isAtBottom()
        self.updateShouldFollowLatestFromFocus()
        let shouldPinToLatest = previousWasAtBottom && self.shouldFollowLatest
        let previousWasWaitingForLoadEarlier = self.isWaitingForLoadEarlier
        let previousWasLoadEarlierInProgress = previousWasWaitingForLoadEarlier || self.isLoadingEarlierHistory
        let loadEarlierInitiationFocus = previousWasLoadEarlierInProgress ? self.loadEarlierInitiationFocus : nil
        let focusedNonTableElementBeforeUpdate = self.focusedNonTableOverlayView()
        let focusedCellIndexPathBeforeUpdate = self.focusedTableViewIndexPath()
        let focusedMessageAnchorBeforeUpdate = self.focusedMessageScrollAnchor()
        let previousRows = self.rows
        let previousOldestIndex = previousRows.first?.index
        let loadEarlierAnchor = previousWasLoadEarlierInProgress ? self.loadEarlierScrollAnchor : nil
        var loadEarlierRestoredIndexPath: IndexPath?

        let previousStableIds = previousRows.map { $0.stableId }
        let newStableIds = newRows.map { $0.stableId }
        if previousStableIds == newStableIds {
            self.rows = newRows
            self.updateRowIndexByStableId()
            self.invalidateAccessibilityElements()
            self.reloadVisibleRows(excluding: focusedCellIndexPathBeforeUpdate)
            if self.forceScrollToBottomOnNextApply {
                self.forceScrollToBottomOnNextApply = false
                if shouldPinToLatest {
                    self.scrollToBottom(animated: false)
                }
            }
            if self.refreshControl.isRefreshing, !previousWasWaitingForLoadEarlier {
                self.refreshControl.endRefreshing()
            }
            if UIAccessibility.isVoiceOverRunning, let focusedNonTableElementBeforeUpdate {
                DispatchQueue.main.async { [weak focusedNonTableElementBeforeUpdate] in
                    guard let focusedNonTableElementBeforeUpdate else {
                        return
                    }
                    UIAccessibility.post(notification: .layoutChanged, argument: focusedNonTableElementBeforeUpdate)
                }
            }
            return
        }

        self.loadEarlierNoProgressCount = 0
        let previousContentOffsetY = self.tableView.contentOffset.y
        let previousContentSizeHeight = self.tableView.contentSize.height
        let insertedCount = newStableIds.count - previousStableIds.count
        let tableRowOffset = self.loadEarlierRowOffset
        let canApplyPrependInsertion: Bool = !previousStableIds.isEmpty && insertedCount > 0 && Array(newStableIds.suffix(previousStableIds.count)) == previousStableIds
        let canApplyAppendInsertion: Bool = !previousStableIds.isEmpty && insertedCount > 0 && Array(newStableIds.prefix(previousStableIds.count)) == previousStableIds
        let preservedTopVisibleIndexPathBeforeUpdate: IndexPath? = {
            guard canApplyPrependInsertion else {
                return nil
            }
            guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.sorted() else {
                return nil
            }
            return visibleIndexPaths.first(where: { $0.row >= tableRowOffset })
        }()
        let preservedTopVisibleOffsetBeforeUpdate: CGFloat? = preservedTopVisibleIndexPathBeforeUpdate.flatMap { indexPath in
            let rect = self.tableView.rectForRow(at: indexPath)
            return rect.minY - previousContentOffsetY
        }
        let preservedScrollAnchor: ScrollAnchor? = {
            if previousWasLoadEarlierInProgress {
                return loadEarlierAnchor
            }
            guard !shouldPinToLatest else {
                return nil
            }
            return focusedMessageAnchorBeforeUpdate ?? self.lastUserScrollAnchor ?? self.currentScrollAnchor()
        }()
        if !shouldPinToLatest, let preservedScrollAnchor {
            self.lastUserScrollAnchor = preservedScrollAnchor
        }

        let didLoadEarlierProgressPreview: Bool
        if previousWasLoadEarlierInProgress, let before = self.loadEarlierOldestIndexBeforeRequest ?? previousOldestIndex, let after = newRows.first?.index, after < before {
            didLoadEarlierProgressPreview = true
        } else {
            didLoadEarlierProgressPreview = false
        }

        self.rows = newRows
        self.updateRowIndexByStableId()
        self.invalidateAccessibilityElements()
        
        var didReloadTable = true
        if canApplyPrependInsertion {
            didReloadTable = false
            self.forceScrollToBottomOnNextApply = false
            
            let insertedIndexPaths = (0 ..< insertedCount).map { IndexPath(row: tableRowOffset + $0, section: 0) }
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertedIndexPaths, with: .none)
                self.tableView.endUpdates()
                self.tableView.layoutIfNeeded()
            }
            
            if let preservedTopVisibleIndexPathBeforeUpdate, let preservedTopVisibleOffsetBeforeUpdate {
                let targetIndexPath = IndexPath(row: preservedTopVisibleIndexPathBeforeUpdate.row + insertedCount, section: 0)
                if targetIndexPath.row < self.tableView.numberOfRows(inSection: 0) {
                    let rect = self.tableView.rectForRow(at: targetIndexPath)
                    let targetOffset = rect.minY - preservedTopVisibleOffsetBeforeUpdate
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(targetOffset)), animated: false)
                } else {
                    let delta = self.tableView.contentSize.height - previousContentSizeHeight
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY + delta)), animated: false)
                }
            } else {
                let delta = self.tableView.contentSize.height - previousContentSizeHeight
                self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY + delta)), animated: false)
            }
        } else if canApplyAppendInsertion {
            didReloadTable = false

            let baseRow = tableRowOffset + previousStableIds.count
            let insertedIndexPaths = (0 ..< insertedCount).map { IndexPath(row: baseRow + $0, section: 0) }
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: insertedIndexPaths, with: .none)
                self.tableView.endUpdates()
                self.tableView.layoutIfNeeded()
            }

            if self.forceScrollToBottomOnNextApply, shouldPinToLatest {
                self.forceScrollToBottomOnNextApply = false
            }
            if shouldPinToLatest {
                self.scrollToBottom(animated: false)
            }
        } else {
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
                self.tableView.layoutIfNeeded()
            }
        }
        
        if didReloadTable {
            if self.rows.isEmpty || !self.didInitialScrollToBottom {
                if !self.didInitialScrollToBottom {
                    self.didInitialScrollToBottom = true
                    self.scrollToBottom(animated: false)
                    self.focusLastMessageIfPossible()
                }
            } else if self.forceScrollToBottomOnNextApply {
                self.forceScrollToBottomOnNextApply = false
                if shouldPinToLatest {
                    self.scrollToBottom(animated: false)
                }
            } else if previousWasLoadEarlierInProgress {
                if let preservedScrollAnchor {
                    let anchoredIndex: Int? = self.indexOfRow(for: preservedScrollAnchor)
                    if let anchoredIndex {
                        let indexPath = IndexPath(row: anchoredIndex + self.loadEarlierRowOffset, section: 0)
                        self.restoreScrollPosition(to: preservedScrollAnchor, at: indexPath)
                        loadEarlierRestoredIndexPath = indexPath
                    } else if didLoadEarlierProgressPreview {
                        let delta = self.tableView.contentSize.height - previousContentSizeHeight
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY + delta)), animated: false)
                    } else {
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY)), animated: false)
                    }
                } else if didLoadEarlierProgressPreview {
                    let delta = self.tableView.contentSize.height - previousContentSizeHeight
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY + delta)), animated: false)
                } else {
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY)), animated: false)
                }
            } else if previousWasAtBottom {
                if shouldPinToLatest {
                    self.scrollToBottom(animated: false)
                } else if let preservedScrollAnchor {
                    if let anchoredIndex = self.indexOfRow(for: preservedScrollAnchor) {
                        let indexPath = IndexPath(row: anchoredIndex + self.loadEarlierRowOffset, section: 0)
                        self.restoreScrollPosition(to: preservedScrollAnchor, at: indexPath)
                    } else {
                        self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY)), animated: false)
                    }
                } else {
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY)), animated: false)
                }
            } else if let preservedScrollAnchor {
                if let anchoredIndex = self.indexOfRow(for: preservedScrollAnchor) {
                    let indexPath = IndexPath(row: anchoredIndex + self.loadEarlierRowOffset, section: 0)
                    self.restoreScrollPosition(to: preservedScrollAnchor, at: indexPath)
                } else {
                    self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY)), animated: false)
                }
            } else if !shouldPinToLatest {
                self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(previousContentOffsetY)), animated: false)
            }
        }

        if self.refreshControl.isRefreshing {
            self.refreshControl.endRefreshing()
        }

        let didLoadEarlierProgress: Bool
        if previousWasLoadEarlierInProgress, let before = self.loadEarlierOldestIndexBeforeRequest ?? previousOldestIndex, let after = self.rows.first?.index, after < before {
            didLoadEarlierProgress = true
            self.endWaitingForLoadEarlierIfNeeded()
            self.reloadLoadEarlierRow()
        } else {
            didLoadEarlierProgress = false
        }
        
        if UIAccessibility.isVoiceOverRunning {
            if didReloadTable {
                let shouldRestoreFocusToMessages = focusedMessageAnchorBeforeUpdate != nil
                let shouldRestoreFocusToLoadEarlierRow = (focusedMessageAnchorBeforeUpdate == nil) && (focusedCellIndexPathBeforeUpdate?.row == 0) && self.shouldShowLoadEarlierRow
                
                let shouldForceRestoreFocusForLoadEarlier = previousWasLoadEarlierInProgress
                let focusTargetIndexPath: IndexPath? = {
                    if shouldRestoreFocusToMessages, let focusedMessageAnchorBeforeUpdate, let index = self.indexOfRow(for: focusedMessageAnchorBeforeUpdate) {
                        return IndexPath(row: index + self.loadEarlierRowOffset, section: 0)
                    }
                    if shouldRestoreFocusToLoadEarlierRow {
                        return IndexPath(row: 0, section: 0)
                    }
                    if let loadEarlierInitiationFocus {
                        switch loadEarlierInitiationFocus {
                        case .loadEarlierRow:
                            if self.shouldShowLoadEarlierRow {
                                return IndexPath(row: 0, section: 0)
                            } else {
                                return nil
                            }
                        case let .message(anchor):
                            if let index = self.indexOfRow(for: anchor) {
                                return IndexPath(row: index + self.loadEarlierRowOffset, section: 0)
                            } else {
                                return nil
                            }
                        }
                    }
                    if shouldForceRestoreFocusForLoadEarlier {
                        if let loadEarlierRestoredIndexPath {
                            return loadEarlierRestoredIndexPath
                        }
                        if let preservedScrollAnchor, let index = self.indexOfRow(for: preservedScrollAnchor) {
                            return IndexPath(row: index + self.loadEarlierRowOffset, section: 0)
                        }
                        if self.shouldShowLoadEarlierRow, !self.rows.isEmpty {
                            return IndexPath(row: self.loadEarlierRowOffset, section: 0)
                        }
                    }
                    return nil
                }()
                    
                if let focusTargetIndexPath {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else {
                            return
                        }
                        guard focusTargetIndexPath.row < self.tableView.numberOfRows(inSection: 0) else {
                            return
                        }

                        let isVisible = self.tableView.indexPathsForVisibleRows?.contains(focusTargetIndexPath) ?? false
                        if !isVisible {
                            UIView.performWithoutAnimation {
                                let position: UITableView.ScrollPosition = (focusTargetIndexPath.row == 0 ? .top : .middle)
                                self.tableView.scrollToRow(at: focusTargetIndexPath, at: position, animated: false)
                                self.tableView.layoutIfNeeded()
                            }
                        }

                        if let element = self.accessibilityElement(at: focusTargetIndexPath) {
                            UIAccessibility.post(notification: .layoutChanged, argument: element)
                        }
                    }
                } else if let focusedNonTableElementBeforeUpdate {
                    DispatchQueue.main.async { [weak focusedNonTableElementBeforeUpdate] in
                        guard let focusedNonTableElementBeforeUpdate else {
                            return
                        }
                        UIAccessibility.post(notification: .layoutChanged, argument: focusedNonTableElementBeforeUpdate)
                    }
                }
            } else if let focusedNonTableElementBeforeUpdate {
                DispatchQueue.main.async { [weak focusedNonTableElementBeforeUpdate] in
                    guard let focusedNonTableElementBeforeUpdate else {
                        return
                    }
                    UIAccessibility.post(notification: .layoutChanged, argument: focusedNonTableElementBeforeUpdate)
                }
            }
        }
        
        if didLoadEarlierProgress {
            self.loadEarlierInitiationFocus = nil
        }
    }

    private func captureLastUserScrollAnchor() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        if let anchor = self.currentScrollAnchor() {
            self.lastUserScrollAnchor = anchor
        }
        self.updateShouldFollowLatestFromFocus()
    }

    private func updateShouldFollowLatestFromFocus() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard let focusedIndexPath = self.focusedTableViewIndexPath() else {
            // When VoiceOver cannot resolve a focused table cell (e.g. during transitions),
            // default to not following latest to avoid unexpected jumps to the bottom.
            self.shouldFollowLatest = false
            return
        }
        let rowOffset = self.loadEarlierRowOffset
        guard focusedIndexPath.row >= rowOffset else {
            self.shouldFollowLatest = false
            return
        }
        guard !self.rows.isEmpty else {
            self.shouldFollowLatest = true
            return
        }
        let lastRow = self.rows.count - 1 + rowOffset
        self.shouldFollowLatest = (focusedIndexPath.row == lastRow)
    }

    private func focusedTableViewIndexPath() -> IndexPath? {
        guard UIAccessibility.isVoiceOverRunning else {
            return nil
        }
        if let focusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? ChatVoiceOverOverlayRowAccessibilityElement {
            return self.indexPath(for: focusedElement)
        }
        guard let focusedView = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView else {
            return nil
        }
        
        var current: UIView? = focusedView
        while let view = current {
            if let cell = view as? UITableViewCell, cell.isDescendant(of: self.tableView) {
                return self.tableView.indexPath(for: cell)
            }
            current = view.superview
        }
        return nil
    }

    private func focusedMessageScrollAnchor() -> ScrollAnchor? {
        guard UIAccessibility.isVoiceOverRunning else {
            return nil
        }
        guard let focusedIndexPath = self.focusedTableViewIndexPath() else {
            return nil
        }
        let rowOffset = self.loadEarlierRowOffset
        let rowIndex = focusedIndexPath.row - rowOffset
        guard rowIndex >= 0, rowIndex < self.rows.count else {
            return nil
        }
        let row = self.rows[rowIndex]
        guard case let .message(message) = row.kind else {
            return nil
        }
        let rect = self.tableView.rectForRow(at: focusedIndexPath)
        let offset = rect.minY - self.tableView.contentOffset.y
        return ScrollAnchor(stableId: row.stableId, messageId: message.id, offset: offset)
    }

    private func reloadVisibleRows(excluding excludedIndexPath: IndexPath? = nil) {
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows, !visibleIndexPaths.isEmpty else {
            return
        }
        let indexPaths: [IndexPath]
        if let excludedIndexPath {
            indexPaths = visibleIndexPaths.filter { $0 != excludedIndexPath }
        } else {
            indexPaths = visibleIndexPaths
        }
        guard !indexPaths.isEmpty else {
            return
        }
        UIView.performWithoutAnimation {
            for indexPath in indexPaths {
                if let cell = self.tableView.cellForRow(at: indexPath) as? ChatVoiceOverOverlayCell {
                    self.configureCell(cell, at: indexPath)
                }
            }
        }
    }

    private func clampContentOffsetY(_ y: CGFloat) -> CGFloat {
        let minOffset = -self.tableView.adjustedContentInset.top
        let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
        return min(max(y, minOffset), maxOffset)
    }

    private func indexOfRow(for anchor: ScrollAnchor) -> Int? {
        if let messageId = anchor.messageId {
            if let index = self.rows.firstIndex(where: { row in
                if case let .message(message) = row.kind {
                    return message.id == messageId
                } else {
                    return false
                }
            }) {
                return index
            }
        }
        return self.rows.firstIndex(where: { $0.stableId == anchor.stableId })
    }

    private func restoreScrollPosition(to anchor: ScrollAnchor, at indexPath: IndexPath) {
        let rect = self.tableView.rectForRow(at: indexPath)
        let targetOffset = rect.minY - anchor.offset
        self.tableView.setContentOffset(CGPoint(x: 0.0, y: self.clampContentOffsetY(targetOffset)), animated: false)
    }

    private func focusedNonTableOverlayView() -> UIView? {
        guard UIAccessibility.isVoiceOverRunning else {
            return nil
        }
        guard let focusedView = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? UIView else {
            return nil
        }
        guard focusedView.isDescendant(of: self) else {
            return nil
        }
        guard !focusedView.isDescendant(of: self.tableView) else {
            return nil
        }
        return focusedView
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
        
        if UIAccessibility.isVoiceOverRunning, self.loadEarlierInitiationFocus == nil {
            if self.shouldShowLoadEarlierRow, self.focusedTableViewIndexPath()?.row == 0 {
                self.loadEarlierInitiationFocus = .loadEarlierRow
            } else if let anchor = self.focusedMessageScrollAnchor() ?? self.currentScrollAnchor() {
                self.loadEarlierInitiationFocus = .message(anchor)
            }
        }

        if UIAccessibility.isVoiceOverRunning {
            self.shouldFollowLatest = false
        }
        self.forceScrollToBottomOnNextApply = false
        if case let .message(anchor)? = self.loadEarlierInitiationFocus {
            self.loadEarlierScrollAnchor = anchor
        } else {
            self.loadEarlierScrollAnchor = self.currentScrollAnchor()
        }
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
            self.loadEarlierInitiationFocus = nil
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
                if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? ChatVoiceOverOverlayCell {
                    self.configureLoadEarlierCell(cell)
                } else {
                    self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
                }
            } else {
                self.tableView.reloadData()
            }
            self.tableView.layoutIfNeeded()
        }
    }
    
    private func maybeEnsureAtLatestIfNeeded() {
        guard !self.isLoadEarlierInProgress else {
            return
        }
        self.updateShouldFollowLatestFromFocus()
        guard !UIAccessibility.isVoiceOverRunning || self.shouldFollowLatest else {
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
        
        if UIAccessibility.isVoiceOverRunning, let focusedIndexPath = self.focusedTableViewIndexPath(), focusedIndexPath.row >= rowOffset {
            let rowIndex = focusedIndexPath.row - rowOffset
            if rowIndex >= 0, rowIndex < self.rows.count, case .message = self.rows[rowIndex].kind {
                if let anchor = makeAnchor(for: focusedIndexPath) {
                    return anchor
                }
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
        let indexPath = IndexPath(row: self.rows.count - 1 + self.loadEarlierRowOffset, section: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            if self.tableView.indexPathsForVisibleRows?.contains(indexPath) != true {
                UIView.performWithoutAnimation {
                    self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                    self.tableView.layoutIfNeeded()
                }
            }
            if let element = self.accessibilityElement(at: indexPath) {
                UIAccessibility.post(notification: .screenChanged, argument: element)
            }
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
