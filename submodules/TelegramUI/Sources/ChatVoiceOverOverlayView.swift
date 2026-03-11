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
import ChatMessageItemCommon
import TextFormat
import TextSelectionNode
import ChatInputTextNode

private final class ChatVoiceOverOverlayTableView: UITableView {
    var onDidPerformAccessibilityScroll: (() -> Void)?
    weak var overlayForAccessibilityElements: ChatVoiceOverOverlayView?
    fileprivate static let voiceOverScrollbarGutterWidth: CGFloat = 22.0
    private static let voiceOverScrollbarAnnouncementPercentStep: Int = 5

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
        if let overlay = self.overlayForAccessibilityElements, let value = overlay.voiceOverScrollbarAccessibilityValue() {
            UIAccessibility.post(notification: .pageScrolled, argument: value)
        } else {
            let range = maxOffset - minOffset
            if range > 1.0 {
                let progress = (self.contentOffset.y - minOffset) / range
                let clamped = max(0.0, min(1.0, progress))
                let rawPercent = (clamped * 100.0)
                let step = max(1, Self.voiceOverScrollbarAnnouncementPercentStep)
                let quantized = Int((rawPercent / CGFloat(step)).rounded()) * step
                let percent = max(0, min(100, quantized))
                UIAccessibility.post(notification: .pageScrolled, argument: "\(percent)%")
            } else {
                UIAccessibility.post(notification: .pageScrolled, argument: nil)
            }
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

    // MARK: - Custom accessibility container (stable swipe navigation)

    override var accessibilityElements: [Any]? {
        get {
            guard UIAccessibility.isVoiceOverRunning else {
                return nil
            }
            guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
                return nil
            }
            return overlay.tableAccessibilityElements
        }
        set {
        }
    }

    override func accessibilityElementCount() -> Int {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.accessibilityElementCount()
        }
        guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
            return super.accessibilityElementCount()
        }
        return overlay.tableAccessibilityElementCount
    }

    override func accessibilityElement(at index: Int) -> Any? {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.accessibilityElement(at: index)
        }
        guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
            return super.accessibilityElement(at: index)
        }
        return overlay.tableAccessibilityElement(at: index)
    }

	    override func index(ofAccessibilityElement element: Any) -> Int {
	        if UIAccessibility.isVoiceOverRunning, let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility {
	            let baseIndex = overlay.tableAccessibilityIndex(of: element)
	            if baseIndex != NSNotFound {
	                return baseIndex
	            }

	            if let scrollbarElement = element as? ChatVoiceOverOverlayScrollbarAccessibilityElement, scrollbarElement.overlay === overlay {
	                if let mappedIndex = self.voiceOverIndexForNativeScrollbar(using: overlay) {
	                    return mappedIndex
	                }
	            }

	            // When the native VoiceOver scrollbar is focused, iOS asks the scroll view container
	            // for its index to resolve swipe-left/right navigation. Since the scrollbar element is
	            // not part of our custom `accessibilityElements`, returning `NSNotFound` makes VoiceOver
	            // fall back to the parent container (e.g. the title), which feels like "falling out"
	            // of the message list. Map the scrollbar to a stable nearby row index instead.
	            if self.isProbablyNativeVoiceOverScrollbarElement(element) {
	                if let mappedIndex = self.voiceOverIndexForNativeScrollbar(using: overlay) {
	                    return mappedIndex
	                }
	            }
	        }
	        return super.index(ofAccessibilityElement: element)
	    }

	    fileprivate func isProbablyNativeVoiceOverScrollbarElement(_ element: Any) -> Bool {
	        if element is ChatVoiceOverOverlayRowAccessibilityElement {
	            return false
	        }

	        // Try to identify the internal scrollbar element by its class name first.
	        // This avoids relying on `accessibilityFrame` for private accessibility objects that
	        // sometimes report inconsistent coordinates.
	        let nameSuggestsScrollbar: Bool = {
	            let object = element as AnyObject
	            guard let cls = object_getClass(object) else {
	                return false
	            }
	            let className = NSStringFromClass(cls).lowercased()
	            if className.contains("scrollbar") {
	                return true
	            }
	            // Common internal naming patterns across iOS versions.
	            if className.contains("scroll") && (className.contains("indicator") || className.contains("ax") || className.contains("accessibility")) {
	                return true
	            }
	            return false
	        }()

	        let labelSuggestsScrollbar: Bool = {
	            guard let label = self.accessibilityLabel(forUnknownElement: element)?.lowercased(), !label.isEmpty else {
	                return false
	            }
	            if label.contains("scrollbar") {
	                return true
	            }
	            if label.contains("scroll") && label.contains("bar") {
	                return true
	            }
	            // A small set of common non-English patterns (best effort).
	            if label.contains("pasek") && label.contains("przew") {
	                return true
	            }
	            return false
	        }()

	        let traitsSuggestScrollbar: Bool = {
	            guard let traits = self.accessibilityTraits(forUnknownElement: element) else {
	                return false
	            }
	            return traits.contains(.adjustable)
	        }()

	        let strongSuggestsScrollbar = nameSuggestsScrollbar || labelSuggestsScrollbar

	        guard let rawFrame = self.accessibilityFrame(forUnknownElement: element) else {
	            return strongSuggestsScrollbar || traitsSuggestScrollbar
	        }
	        guard !rawFrame.isEmpty,
	              rawFrame.origin.x.isFinite,
	              rawFrame.origin.y.isFinite,
	              rawFrame.size.width.isFinite,
	              rawFrame.size.height.isFinite
	        else {
	            return strongSuggestsScrollbar || traitsSuggestScrollbar
	        }

        let tableFrame = self.convert(self.bounds, to: nil)
        let frame: CGRect = {
            // `accessibilityFrame` is expected to be in screen coordinates, but some internal
            // accessibility objects occasionally return a frame in container coordinates.
            // Prefer the variant that actually overlaps the table view on screen.
            if tableFrame.intersects(rawFrame) {
                return rawFrame
            }
            let converted = self.convert(rawFrame, to: nil)
            if tableFrame.intersects(converted) {
                return converted
            }
            return rawFrame
	        }()
	        guard tableFrame.intersects(frame) else {
	            return strongSuggestsScrollbar || traitsSuggestScrollbar
	        }

        // The scrollbar sits in a thin strip on the right side of the scroll view.
        let gutter = CGRect(
            x: tableFrame.maxX - Self.voiceOverScrollbarGutterWidth - 12.0,
            y: tableFrame.minY - 24.0,
            width: Self.voiceOverScrollbarGutterWidth + 24.0,
            height: tableFrame.height + 48.0
	        )
	        guard gutter.intersects(frame) else {
	            return strongSuggestsScrollbar
	        }

	        return true
	    }

    private func accessibilityFrame(forUnknownElement element: Any) -> CGRect? {
        if let view = element as? UIView {
            return view.accessibilityFrame
        }
        if let accessibilityElement = element as? UIAccessibilityElement {
            return accessibilityElement.accessibilityFrame
        }

        let selector = NSSelectorFromString("accessibilityFrame")
        let object = element as AnyObject
        guard object.responds(to: selector) else {
            return nil
        }
        guard let baseClass = object_getClass(object),
              let method = class_getInstanceMethod(baseClass, selector)
        else {
            return nil
        }

        typealias FrameIMP = @convention(c) (AnyObject, Selector) -> CGRect
        let imp = method_getImplementation(method)
        let fn = unsafeBitCast(imp, to: FrameIMP.self)
        return fn(object, selector)
    }

	    private func accessibilityTraits(forUnknownElement element: Any) -> UIAccessibilityTraits? {
	        if let view = element as? UIView {
	            return view.accessibilityTraits
	        }
	        if let accessibilityElement = element as? UIAccessibilityElement {
	            return accessibilityElement.accessibilityTraits
	        }

        let selector = NSSelectorFromString("accessibilityTraits")
        let object = element as AnyObject
        guard object.responds(to: selector) else {
            return nil
        }
        guard let baseClass = object_getClass(object),
              let method = class_getInstanceMethod(baseClass, selector)
        else {
            return nil
        }

        typealias TraitsIMP = @convention(c) (AnyObject, Selector) -> UInt64
        let imp = method_getImplementation(method)
	        let fn = unsafeBitCast(imp, to: TraitsIMP.self)
	        return UIAccessibilityTraits(rawValue: fn(object, selector))
	    }

	    private func accessibilityLabel(forUnknownElement element: Any) -> String? {
	        if let view = element as? UIView {
	            return view.accessibilityLabel
	        }
	        if let accessibilityElement = element as? UIAccessibilityElement {
	            return accessibilityElement.accessibilityLabel
	        }

	        let selector = NSSelectorFromString("accessibilityLabel")
	        let object = element as AnyObject
	        guard object.responds(to: selector) else {
	            return nil
	        }
	        guard let baseClass = object_getClass(object),
	              let method = class_getInstanceMethod(baseClass, selector)
	        else {
	            return nil
	        }

	        typealias LabelIMP = @convention(c) (AnyObject, Selector) -> AnyObject?
	        let imp = method_getImplementation(method)
	        let fn = unsafeBitCast(imp, to: LabelIMP.self)
	        return fn(object, selector) as? String
	    }

    private func voiceOverIndexForNativeScrollbar(using overlay: ChatVoiceOverOverlayView) -> Int? {
        let elementCount = overlay.tableAccessibilityElementCount
        guard elementCount > 0 else {
            return nil
        }

        // Always map the scrollbar to the nearest currently visible message row.
        // This keeps swipe-left from the native VoiceOver scrollbar inside the list, without
        // jumping to the title bar or to an off-screen message.
        guard let visibleIndexPaths = self.indexPathsForVisibleRows?.sorted(), !visibleIndexPaths.isEmpty else {
            return nil
        }

        let hasLoadEarlierRow: Bool = {
            guard let first = overlay.tableAccessibilityElement(at: 0) as? ChatVoiceOverOverlayRowAccessibilityElement else {
                return false
            }
            if case .loadEarlier = first.kind {
                return true
            } else {
                return false
            }
        }()
        let firstMessageRow = hasLoadEarlierRow ? 1 : 0

        let candidates = visibleIndexPaths.filter { $0.section == 0 && $0.row >= firstMessageRow }
        let effectiveCandidates = candidates.isEmpty ? visibleIndexPaths : candidates
        let anchorIndexPath: IndexPath = {
            let rowCount = max(0, self.numberOfRows(inSection: 0))
            if rowCount > 0, visibleIndexPaths.contains(where: { $0.section == 0 && $0.row == rowCount - 1 }), let last = effectiveCandidates.last {
                return last
            }
            if visibleIndexPaths.contains(where: { $0.section == 0 && $0.row == 0 }), let first = effectiveCandidates.first {
                return first
            }
            let visibleMidY = self.contentOffset.y + self.bounds.height * 0.5
            var best = effectiveCandidates[0]
            var bestDistance = abs(self.rectForRow(at: best).midY - visibleMidY)
            for indexPath in effectiveCandidates.dropFirst() {
                let distance = abs(self.rectForRow(at: indexPath).midY - visibleMidY)
                if distance < bestDistance {
                    bestDistance = distance
                    best = indexPath
                }
            }
            return best
        }()
        let anchorRow = anchorIndexPath.row

        let clampedAnchor = min(max(anchorRow, firstMessageRow), elementCount - 1)

        // Return an index such that swipe-left always stays inside the message list.
        // VoiceOver focuses `index - 1` when swiping left from the scrollbar.
        return min(clampedAnchor + 1, elementCount - 1)
    }

    // MARK: - Touch exploration hit-testing

    private func voiceOverCustomHitTest(_ point: CGPoint) -> Any? {
        let localPoint = self.normalizeAccessibilityHitTestPointToLocal(point)
        return self.voiceOverCustomHitTestInContainerSpace(localPoint)
    }

    private func voiceOverCustomHitTestInContainerSpace(_ point: CGPoint) -> Any? {
        guard UIAccessibility.isVoiceOverRunning, let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
            return nil
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
}

private final class ChatVoiceOverOverlayAccessibilityContainerView: UIView {
    weak var overlayForAccessibilityElements: ChatVoiceOverOverlayView?

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

    private func voiceOverCustomHitTest(_ point: CGPoint) -> Any? {
        guard UIAccessibility.isVoiceOverRunning, let overlay = self.overlayForAccessibilityElements else {
            return nil
        }
        let localPoint = self.normalizeAccessibilityHitTestPointToLocal(point)
        return overlay.voiceOverAccessibilityContainerHitTest(pointInContainerSpace: localPoint)
    }

    override var accessibilityElements: [Any]? {
        get {
            guard UIAccessibility.isVoiceOverRunning else {
                return nil
            }
            guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
                return super.accessibilityElements
            }
            return overlay.tableAccessibilityElements
        }
        set {
        }
    }

    override func accessibilityElementCount() -> Int {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.accessibilityElementCount()
        }
        guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
            return super.accessibilityElementCount()
        }
        return overlay.tableAccessibilityElementCount
    }

    override func accessibilityElement(at index: Int) -> Any? {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.accessibilityElement(at: index)
        }
        guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
            return super.accessibilityElement(at: index)
        }
        return overlay.tableAccessibilityElement(at: index)
    }

    override func index(ofAccessibilityElement element: Any) -> Int {
        guard UIAccessibility.isVoiceOverRunning else {
            return super.index(ofAccessibilityElement: element)
        }
        guard let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility else {
            return super.index(ofAccessibilityElement: element)
        }
        return overlay.tableAccessibilityIndex(of: element)
    }

    // iOS 17 and earlier.
    @objc(accessibilityHitTest:)
    func accessibilityHitTest(_ point: CGPoint) -> Any? {
        if let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility, let element = self.voiceOverCustomHitTest(point) {
            return element
        }
        if #available(iOS 18.0, *) {
            return super.accessibilityHitTest(point, event: nil)
        }

        let selector = NSSelectorFromString("accessibilityHitTest:")
        let baseMethod =
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
        if let overlay = self.overlayForAccessibilityElements, !overlay.usesNativeVoiceOverAccessibility, let element = self.voiceOverCustomHitTest(point) {
            return element
        }
        return super.accessibilityHitTest(point, event: event)
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

private final class VoiceOverChatComposerTextView: ChatInputTextView {
    var onRequestSend: (() -> Bool)?
    var onPerformEscape: (() -> Bool)?

    private var isPerformingExplicitLineBreak = false

    override func accessibilityPerformEscape() -> Bool {
        if self.onPerformEscape?() == true {
            return true
        }
        return super.accessibilityPerformEscape()
    }

    @objc override func insertNewline(_ sender: Any?) {
        if UIAccessibility.isVoiceOverRunning,
           !self.isPerformingExplicitLineBreak,
           self.onRequestSend?() == true {
            return
        }
        self.insertText("\n")
    }

    @objc override func insertLineBreak(_ sender: Any?) {
        self.isPerformingExplicitLineBreak = true
        defer {
            self.isPerformingExplicitLineBreak = false
        }
        self.insertText("\n")
    }

    @objc override func insertParagraphSeparator(_ sender: Any?) {
        self.isPerformingExplicitLineBreak = true
        defer {
            self.isPerformingExplicitLineBreak = false
        }
        self.insertText("\n")
    }
}

private final class ChatVoiceOverOverlayScrollbarAccessibilityElement: UIAccessibilityElement {
    weak var overlay: ChatVoiceOverOverlayView?

    init(container: AnyObject, overlay: ChatVoiceOverOverlayView) {
        self.overlay = overlay
        super.init(accessibilityContainer: container)
        self.isAccessibilityElement = true
    }

    override var accessibilityFrameInContainerSpace: CGRect {
        get {
            return self.overlay?.voiceOverScrollbarAccessibilityFrameInContainerSpace() ?? .zero
        }
        set {
        }
    }

    override var accessibilityFrame: CGRect {
        get {
            return self.overlay?.voiceOverScrollbarAccessibilityFrameInScreenSpace() ?? .zero
        }
        set {
        }
    }

    override var accessibilityLabel: String? {
        get {
            return self.overlay?.voiceOverScrollbarAccessibilityLabel()
        }
        set {
        }
    }

    override var accessibilityHint: String? {
        get {
            return self.overlay?.voiceOverScrollbarAccessibilityHint()
        }
        set {
        }
    }

    override var accessibilityValue: String? {
        get {
            return self.overlay?.voiceOverScrollbarAccessibilityValue()
        }
        set {
        }
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return [.adjustable]
        }
        set {
        }
    }

    override func accessibilityIncrement() {
        self.overlay?.voiceOverScrollbarAccessibilityIncrement()
    }

    override func accessibilityDecrement() {
        self.overlay?.voiceOverScrollbarAccessibilityDecrement()
    }

    override func accessibilityElementDidBecomeFocused() {
        super.accessibilityElementDidBecomeFocused()
        self.overlay?.noteVoiceOverNavigationActivity()
    }

    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return self.overlay?.voiceOverScrollbarAccessibilityCustomActions()
        }
        set {
        }
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

    override var accessibilityValue: String? {
        get {
            return self.overlay?.voiceOverAccessibilityValue(for: self)
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
    public struct MessageTextActionItem: Equatable {
        public let action: TelegramTextAttributesVoiceOver.Action
        public let title: String

        public init(action: TelegramTextAttributesVoiceOver.Action, title: String) {
            self.action = action
            self.title = title
        }
    }

    private enum MessageActivation {
        case none
        case openPoll
        case openTodo
        case toggleVoicePlayback
        case openDefault
        case openTextAction(TelegramTextAttributesVoiceOver.Action)
        case presentTextActions([MessageTextActionItem])
    }

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
        public var openPollMessage: ((Message) -> Void)?
        public var openTodoMessage: ((Message) -> Void)?
        public var toggleVoiceMessagePlayback: ((Message) -> Void)?
        public var toggleCurrentVoicePlayback: (() -> Void)?
        public var seekCurrentVoicePlayback: ((Double) -> Void)?
        public var setCurrentVoicePlaybackRate: ((Double) -> Void)?
        public var openMessageContextMenu: ((Message, CGRect) -> Void)?
        public var activateMessageTextAction: ((Message, TelegramTextAttributesVoiceOver.Action) -> Void)?
        public var presentMessageTextActions: ((Message, [MessageTextActionItem]) -> Void)?
        public var performTextSelectionAction: ((Message, NSAttributedString, TextSelectionAction) -> Void)?
        public var requestAudioTranscription: ((Message) -> Void)?
        public var viewAudioTranscript: ((Message) -> Void)?
        public var requestVisibleTranslations: (([MessageId]) -> Void)?

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
            openPollMessage: ((Message) -> Void)? = nil,
            openTodoMessage: ((Message) -> Void)? = nil,
            toggleVoiceMessagePlayback: ((Message) -> Void)? = nil,
            toggleCurrentVoicePlayback: (() -> Void)? = nil,
            seekCurrentVoicePlayback: ((Double) -> Void)? = nil,
            setCurrentVoicePlaybackRate: ((Double) -> Void)? = nil,
            openMessageContextMenu: ((Message, CGRect) -> Void)? = nil,
            activateMessageTextAction: ((Message, TelegramTextAttributesVoiceOver.Action) -> Void)? = nil,
            presentMessageTextActions: ((Message, [MessageTextActionItem]) -> Void)? = nil,
            performTextSelectionAction: ((Message, NSAttributedString, TextSelectionAction) -> Void)? = nil,
            requestAudioTranscription: ((Message) -> Void)? = nil,
            viewAudioTranscript: ((Message) -> Void)? = nil,
            requestVisibleTranslations: (([MessageId]) -> Void)? = nil
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
            self.openPollMessage = openPollMessage
            self.openTodoMessage = openTodoMessage
            self.toggleVoiceMessagePlayback = toggleVoiceMessagePlayback
            self.toggleCurrentVoicePlayback = toggleCurrentVoicePlayback
            self.seekCurrentVoicePlayback = seekCurrentVoicePlayback
            self.setCurrentVoicePlaybackRate = setCurrentVoicePlaybackRate
            self.openMessageContextMenu = openMessageContextMenu
            self.activateMessageTextAction = activateMessageTextAction
            self.presentMessageTextActions = presentMessageTextActions
            self.performTextSelectionAction = performTextSelectionAction
            self.requestAudioTranscription = requestAudioTranscription
            self.viewAudioTranscript = viewAudioTranscript
            self.requestVisibleTranslations = requestVisibleTranslations
        }
    }

    private struct Row {
        enum Kind {
            case message(Message)
            case unreadMarker
            case info(String)
        }

        var stableId: UInt64
        var index: MessageIndex
        var kind: Kind
    }

    fileprivate let usesNativeVoiceOverAccessibility: Bool = true

    private let topBarView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let profileButton = UIButton(type: .system)

    private let tableView = ChatVoiceOverOverlayTableView(frame: .zero, style: .plain)
    private let tableAccessibilityContainerView = ChatVoiceOverOverlayAccessibilityContainerView()
    private let refreshControl = UIRefreshControl()

    fileprivate lazy var voiceOverScrollbarAccessibilityElement: ChatVoiceOverOverlayScrollbarAccessibilityElement = {
        return ChatVoiceOverOverlayScrollbarAccessibilityElement(container: self.tableAccessibilityContainerView, overlay: self)
    }()

    private let composerView = UIView()
    private let attachButton = UIButton(type: .system)
    private let inputTextNode = ChatInputTextNode(
        disableTiling: true,
        textViewFactory: { disableTiling in
            return VoiceOverChatComposerTextView(disableTiling: disableTiling)
        }
    )
    private let recordButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)

    private let voicePlayerView = UIView()
    private let voicePlayerPlayPauseButton = UIButton(type: .system)
    private let voicePlayerSpeedButton = UIButton(type: .system)
    private let voicePlayerPositionSlider = UISlider()
    private var voicePlayerHeightConstraint: NSLayoutConstraint?
    private var voicePlayerSeekWorkItem: DispatchWorkItem?
    private var isUpdatingVoicePlayerSlider = false

    struct VoicePlaybackState: Equatable {
        var messageId: MessageId
        var isPlaying: Bool
        var position: Double
        var duration: Double
        var baseRate: Double
    }

    private var voicePlaybackState: VoicePlaybackState?

    private var composerBottomConstraint: NSLayoutConstraint?
    private var composerHeightConstraint: NSLayoutConstraint?
    private var keyboardObservers: [NSObjectProtocol] = []
    private var accessibilityObservers: [NSObjectProtocol] = []

    private var interfaceState: ChatPresentationInterfaceState?
    private var rows: [Row] = []
    private var rowIndexByStableId: [UInt64: Int] = [:]

    private var cachedAccessibilityElements: [Any] = []
    private var needsAccessibilityElementsRebuild = true
    private var isRebuildingAccessibilityElements = false

    private var loadEarlierAccessibilityElement: ChatVoiceOverOverlayRowAccessibilityElement?
    private var rowAccessibilityElementsByStableId: [UInt64: ChatVoiceOverOverlayRowAccessibilityElement] = [:]
    fileprivate var lastFocusedTableIndexPathForScroll: IndexPath?

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

    private var lastEntriesApplyTimestamp: CFTimeInterval = 0.0
    private var lastApplyWasStableIdsOnly: Bool = false
    private var lastStableIdsOnlyVisibleReloadTimestamp: CFTimeInterval = 0.0
    private var voiceOverFocusRecoveryWorkItem: DispatchWorkItem?
    private var keyboardDismissFocusRestoreWorkItem: DispatchWorkItem?
    private var lastKnownKeyboardOverlap: CGFloat = 0.0
    private var voiceOverModalIsolationGraceDeadline: CFTimeInterval = 0.0

    private var lastVoiceOverNavigationTimestamp: CFTimeInterval = 0.0
    private var voiceOverScrollbarAccessibilityElementAnchorTableRow: Int?
    private var cachedVoiceOverScrollbarAccessibilityElementIndex: Int?
    private var messageTextActionItemsCache: [MessageId: [MessageTextActionItem]] = [:]

    public var actions = Actions()

    private static let maxLoadEarlierNoProgressCount: Int = 200
    private static let loadEarlierTimeout: TimeInterval = 12.0
    private static let voiceOverScrollbarPercentStep: Int = 5

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

    private var inputTextView: ChatInputTextView {
        return self.inputTextNode.textView
    }

    private var voiceOverComposerTextView: VoiceOverChatComposerTextView? {
        return self.inputTextNode.textView as? VoiceOverChatComposerTextView
    }

    private func composerAccessibilityElementsList() -> [Any] {
        guard !self.composerView.accessibilityElementsHidden, self.isComposerEnabled else {
            return []
        }
        var elements: [Any] = [
            self.attachButton,
            self.inputTextView
        ]
        if !self.sendButton.isHidden && self.sendButton.isAccessibilityElement {
            elements.append(self.sendButton)
        }
        if !self.recordButton.isHidden && self.recordButton.isAccessibilityElement {
            elements.append(self.recordButton)
        }
        return elements
    }

    private func voicePlayerAccessibilityElementsList() -> [Any] {
        guard !self.voicePlayerView.isHidden, !self.voicePlayerView.accessibilityElementsHidden else {
            return []
        }
        return [
            self.voicePlayerPlayPauseButton,
            self.voicePlayerPositionSlider,
            self.voicePlayerSpeedButton
        ]
    }

    public override var accessibilityElements: [Any]? {
        get {
            guard UIAccessibility.isVoiceOverRunning else {
                return nil
            }
            if self.usesNativeVoiceOverAccessibility {
                var elements: [Any] = [
                    self.backButton,
                    self.profileButton,
                    self.titleLabel,
                    self.tableView
                ]
                elements.append(contentsOf: self.voicePlayerAccessibilityElementsList())
                elements.append(contentsOf: self.composerAccessibilityElementsList())
                return elements
            }
            var elements: [Any] = [
                self.backButton,
                self.profileButton,
                self.titleLabel,
                self.tableAccessibilityContainerView
            ]
            if !self.voicePlayerView.isHidden && !self.voicePlayerView.accessibilityElementsHidden {
                elements.append(self.voicePlayerView)
            }
            if !self.composerView.accessibilityElementsHidden {
                elements.append(self.composerView)
            }
            return elements
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
        self.tableView.onDidPerformAccessibilityScroll = { [weak self] in
            self?.voiceOverScrollbarDidPerformAccessibilityScroll()
        }
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
        // Hide the table view from the accessibility tree to prevent iOS from exposing its
        // own VoiceOver scrollbar element ("two scrollbars" effect). We expose messages and
        // a single stable scrollbar via `tableAccessibilityContainerView` instead.
        self.tableView.accessibilityElementsHidden = !self.usesNativeVoiceOverAccessibility
        self.refreshControl.addTarget(self, action: #selector(self.refreshTriggered), for: .valueChanged)
        self.tableView.refreshControl = self.refreshControl
        self.addSubview(self.tableView)

        self.tableAccessibilityContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.tableAccessibilityContainerView.overlayForAccessibilityElements = self
        self.tableAccessibilityContainerView.isAccessibilityElement = false
        self.tableAccessibilityContainerView.backgroundColor = .clear
        // Don't block touches/scrolling when VoiceOver is not interacting with accessibility.
        self.tableAccessibilityContainerView.isUserInteractionEnabled = false
        self.tableAccessibilityContainerView.isHidden = self.usesNativeVoiceOverAccessibility
        self.tableAccessibilityContainerView.accessibilityElementsHidden = self.usesNativeVoiceOverAccessibility
        self.addSubview(self.tableAccessibilityContainerView)

        self.composerView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.composerView)

        self.voicePlayerView.translatesAutoresizingMaskIntoConstraints = false
        self.voicePlayerView.isHidden = true
        self.voicePlayerView.isUserInteractionEnabled = false
        self.voicePlayerView.isAccessibilityElement = false
        self.addSubview(self.voicePlayerView)

        self.voicePlayerPlayPauseButton.translatesAutoresizingMaskIntoConstraints = false
        self.voicePlayerPlayPauseButton.addTarget(self, action: #selector(self.voicePlayerPlayPausePressed), for: .touchUpInside)
        self.voicePlayerView.addSubview(self.voicePlayerPlayPauseButton)

        self.voicePlayerSpeedButton.translatesAutoresizingMaskIntoConstraints = false
        self.voicePlayerSpeedButton.addTarget(self, action: #selector(self.voicePlayerSpeedPressed), for: .touchUpInside)
        self.voicePlayerView.addSubview(self.voicePlayerSpeedButton)

        self.voicePlayerPositionSlider.translatesAutoresizingMaskIntoConstraints = false
        self.voicePlayerPositionSlider.addTarget(self, action: #selector(self.voicePlayerSliderValueChanged), for: .valueChanged)
        self.voicePlayerView.addSubview(self.voicePlayerPositionSlider)

        self.attachButton.translatesAutoresizingMaskIntoConstraints = false
        self.attachButton.addTarget(self, action: #selector(self.attachPressed), for: .touchUpInside)
        self.composerView.addSubview(self.attachButton)

        self.inputTextNode.delegate = self
        self.inputTextNode.view.translatesAutoresizingMaskIntoConstraints = false
        self.inputTextView.font = UIFont.preferredFont(forTextStyle: .body)
        self.inputTextView.adjustsFontForContentSizeCategory = true
        self.inputTextView.isScrollEnabled = true
        self.inputTextView.layer.cornerRadius = 10.0
        self.inputTextView.layer.masksToBounds = true
        self.inputTextNode.textContainerInset = UIEdgeInsets(top: 8.0, left: 6.0, bottom: 8.0, right: 6.0)
        self.inputTextView.returnKeyType = .default
        self.inputTextView.enablesReturnKeyAutomatically = false
        self.voiceOverComposerTextView?.onRequestSend = { [weak self] in
            return self?.sendCurrentInputText() ?? false
        }
        self.voiceOverComposerTextView?.onPerformEscape = { [weak self] in
            guard let self else {
                return false
            }
            guard self.inputTextView.isFirstResponder || self.lastKnownKeyboardOverlap > 0.0 || self.hasFirstResponderDescendant() else {
                return false
            }
            self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)
            self.endEditing(true)
            self.scheduleKeyboardDismissFocusRestoreIfNeeded(after: 0.08)
            return true
        }
        self.composerView.addSubview(self.inputTextNode.view)

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

        let voicePlayerHeightConstraint = self.voicePlayerView.heightAnchor.constraint(equalToConstant: 0.0)
        self.voicePlayerHeightConstraint = voicePlayerHeightConstraint

        NSLayoutConstraint.activate([
            self.topBarView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            self.topBarView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.topBarView.trailingAnchor.constraint(equalTo: self.trailingAnchor),

            self.backButton.leadingAnchor.constraint(equalTo: self.topBarView.leadingAnchor, constant: 12.0),
            self.backButton.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),

            // Keep the Chat Info button away from the right edge so it doesn't become the
            // "previous element" when navigating from the native VoiceOver scrollbar.
            self.profileButton.leadingAnchor.constraint(equalTo: self.backButton.trailingAnchor, constant: 12.0),
            self.profileButton.centerYAnchor.constraint(equalTo: self.titleLabel.centerYAnchor),

            self.titleLabel.topAnchor.constraint(equalTo: self.topBarView.topAnchor, constant: 10.0),
            self.titleLabel.bottomAnchor.constraint(equalTo: self.topBarView.bottomAnchor, constant: -10.0),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.profileButton.trailingAnchor, constant: 12.0),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: self.topBarView.trailingAnchor, constant: -12.0),
            self.titleLabel.centerXAnchor.constraint(equalTo: self.topBarView.centerXAnchor),

            self.composerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.composerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            composerBottom,
            composerHeight,

            self.voicePlayerView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.voicePlayerView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.voicePlayerView.bottomAnchor.constraint(equalTo: self.composerView.topAnchor),
            voicePlayerHeightConstraint,

            self.voicePlayerPlayPauseButton.leadingAnchor.constraint(equalTo: self.voicePlayerView.leadingAnchor, constant: 12.0),
            self.voicePlayerPlayPauseButton.centerYAnchor.constraint(equalTo: self.voicePlayerView.centerYAnchor),
            self.voicePlayerPlayPauseButton.widthAnchor.constraint(equalToConstant: 44.0),
            self.voicePlayerPlayPauseButton.heightAnchor.constraint(equalToConstant: 44.0),

            self.voicePlayerSpeedButton.trailingAnchor.constraint(equalTo: self.voicePlayerView.trailingAnchor, constant: -12.0),
            self.voicePlayerSpeedButton.centerYAnchor.constraint(equalTo: self.voicePlayerView.centerYAnchor),
            self.voicePlayerSpeedButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44.0),
            self.voicePlayerSpeedButton.heightAnchor.constraint(equalToConstant: 44.0),

            self.voicePlayerPositionSlider.leadingAnchor.constraint(equalTo: self.voicePlayerPlayPauseButton.trailingAnchor, constant: 10.0),
            self.voicePlayerPositionSlider.trailingAnchor.constraint(equalTo: self.voicePlayerSpeedButton.leadingAnchor, constant: -10.0),
            self.voicePlayerPositionSlider.centerYAnchor.constraint(equalTo: self.voicePlayerView.centerYAnchor),

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

            self.inputTextNode.view.leadingAnchor.constraint(equalTo: self.attachButton.trailingAnchor, constant: 8.0),
            self.inputTextNode.view.trailingAnchor.constraint(equalTo: self.recordButton.leadingAnchor, constant: -8.0),
            self.inputTextNode.view.topAnchor.constraint(equalTo: self.composerView.topAnchor, constant: 10.0),
            self.inputTextNode.view.bottomAnchor.constraint(equalTo: self.composerView.bottomAnchor, constant: -10.0),
            self.inputTextNode.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 44.0),
            self.inputTextNode.view.heightAnchor.constraint(lessThanOrEqualToConstant: 120.0),

            self.tableView.topAnchor.constraint(equalTo: self.topBarView.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.voicePlayerView.topAnchor),

            self.tableAccessibilityContainerView.topAnchor.constraint(equalTo: self.tableView.topAnchor),
            self.tableAccessibilityContainerView.leadingAnchor.constraint(equalTo: self.tableView.leadingAnchor),
            self.tableAccessibilityContainerView.trailingAnchor.constraint(equalTo: self.tableView.trailingAnchor),
            self.tableAccessibilityContainerView.bottomAnchor.constraint(equalTo: self.tableView.bottomAnchor)
        ])

        self.composerView.setContentHuggingPriority(.required, for: .vertical)
        self.composerView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.tableView.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.tableView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        self.setupKeyboardObservers()
        self.setupAccessibilityObservers()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        let nc = NotificationCenter.default
        for token in self.keyboardObservers {
            nc.removeObserver(token)
        }
        for token in self.accessibilityObservers {
            nc.removeObserver(token)
        }
    }

    func updateInterfaceState(_ state: ChatPresentationInterfaceState) {
        let previousActiveTranslationLanguage = self.activeTranslationLanguage(for: self.interfaceState)
        self.interfaceState = state
        if state.renderedPeer?.peer != nil {
            self.isComposerEnabled = canSendMessagesToChat(state)
        } else {
            self.isComposerEnabled = true
        }

        self.backgroundColor = state.theme.list.plainBackgroundColor
        self.topBarView.backgroundColor = state.theme.rootController.navigationBar.opaqueBackgroundColor
        self.composerView.backgroundColor = state.theme.chat.inputPanel.panelBackgroundColor
        self.voicePlayerView.backgroundColor = state.theme.chat.inputPanel.panelBackgroundColor
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
        self.reconcileVoiceOverScrollbarFocusIfNeeded()
        self.updateComposerAccessibilityVisibility()

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
        self.updateVoicePlayerControls()
        if previousActiveTranslationLanguage != self.activeTranslationLanguage(for: state) {
            self.messageTextActionItemsCache.removeAll(keepingCapacity: true)
            self.tableView.reloadData()
        }
        self.requestVisibleTranslationsIfNeeded()
        self.invalidateAccessibilityElements()
    }

    func voiceOverDidReturnToChat() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)
        self.scheduleVoiceOverFocusRecoveryIfNeeded()

        let restoreFocus: () -> Void = { [weak self] in
            guard let self else {
                return
            }
            let targetIndexPath = self.voiceOverFallbackFocusIndexPath()
            if let targetIndexPath, let target = self.accessibilityFocusTarget(at: targetIndexPath) {
                UIAccessibility.post(notification: .screenChanged, argument: target)
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
            }
        }

        DispatchQueue.main.async(execute: restoreFocus)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: restoreFocus)
    }

    func updateVoicePlaybackState(_ state: VoicePlaybackState?) {
        assert(Thread.isMainThread)
        self.voicePlaybackState = state
        self.updateVoicePlayerControls()
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
        } else if UIAccessibility.isVoiceOverRunning, !self.isLoadEarlierInProgress {
            if self.lastApplyWasStableIdsOnly {
                // Upload/progress updates can trigger very frequent history refreshes.
                // Throttle them to keep VoiceOver responsive and avoid focus churn.
                delay = 0.15
            } else {
                delay = 0.05
            }
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
            self.updateComposerPrimaryActionButtons()
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

        self.updateComposerPrimaryActionButtons()
    }

    private func hasComposerDraftText() -> Bool {
        return !self.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func updateComposerPrimaryActionButtons() {
        let isRecording = self.interfaceState?.inputTextPanelState.mediaRecordingState != nil
        let hasDraftText = self.hasComposerDraftText()
        let shouldShowSend = self.isComposerEnabled && !isRecording && hasDraftText
        let shouldShowRecord = !shouldShowSend

        self.sendButton.isHidden = !shouldShowSend
        self.sendButton.isAccessibilityElement = shouldShowSend
        self.sendButton.accessibilityElementsHidden = !shouldShowSend
        self.sendButton.isEnabled = self.isComposerEnabled && shouldShowSend

        self.recordButton.isHidden = !shouldShowRecord
        self.recordButton.isAccessibilityElement = shouldShowRecord
        self.recordButton.accessibilityElementsHidden = !shouldShowRecord

        self.updateComposerAccessibilityVisibility()
    }

    private func makeRows(from entries: [ChatHistoryEntry]) -> [Row] {
        var result: [Row] = []

        let sortedEntries = entries.sorted()
        for entry in sortedEntries {
            switch entry {
            case let .MessageEntry(message, _, _, _, _, _):
                result.append(Row(stableId: entry.stableId, index: message.index, kind: .message(message)))
            case let .MessageGroupEntry(_, messages, _):
                if let message = messages.last?.0 {
                    result.append(Row(stableId: entry.stableId, index: message.index, kind: .message(message)))
                }
            case .UnreadEntry:
                result.append(Row(stableId: entry.stableId, index: entry.index, kind: .unreadMarker))
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
        // to keep swipe navigation stable.
        if UIAccessibility.isVoiceOverRunning && !self.usesNativeVoiceOverAccessibility {
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
        cell.selectionStyle = .none
        cell.textLabel?.text = resolved.title
        cell.textLabel?.textColor = state.theme.list.itemPrimaryTextColor
        cell.textLabel?.textAlignment = .natural
        cell.detailTextLabel?.text = resolved.subtitle
        cell.detailTextLabel?.textColor = state.theme.list.itemSecondaryTextColor

        if case .unreadMarker = row.kind {
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = state.theme.list.itemAccentColor
        }

        cell.accessibilityLabel = resolved.accessibilityLabel
        cell.accessibilityHint = resolved.hint
        var traits = resolved.traits
        if case .message = row.kind, !self.usesNativeVoiceOverAccessibility {
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

            cell.accessibilityCustomActions = self.makeMessageAccessibilityCustomActions(message: message, state: state, menuRectProvider: { [weak self] in
                guard let self else {
                    return nil
                }
                return self.tableView.convert(self.tableView.rectForRow(at: indexPath), to: self)
            })
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
        case .unreadMarker:
            return nil
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
            _ = self.activateMessageRow(message)
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
        case .unreadMarker:
            return 44.0
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
        self.requestVisibleTranslationsIfNeeded()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === self.tableView else {
            return
        }
        if !decelerate {
            self.captureLastUserScrollAnchor()
            self.applyPendingEntriesIfPossible()
            self.maybeEnsureAtLatestIfNeeded()
            self.requestVisibleTranslationsIfNeeded()
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.captureLastUserScrollAnchor()
        self.applyPendingEntriesIfPossible()
        self.maybeEnsureAtLatestIfNeeded()
        self.requestVisibleTranslationsIfNeeded()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard scrollView === self.tableView else {
            return
        }
        self.captureLastUserScrollAnchor()
        self.applyPendingEntriesIfPossible()
        self.maybeEnsureAtLatestIfNeeded()
        self.requestVisibleTranslationsIfNeeded()
    }

    // MARK: - ChatInputTextNodeDelegate

    public func chatInputTextNodeDidBeginEditing() {
        self.keyboardDismissFocusRestoreWorkItem?.cancel()
        self.keyboardDismissFocusRestoreWorkItem = nil
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .layoutChanged, argument: self.inputTextView)
        }
    }

    public func chatInputTextNodeDidFinishEditing() {
        self.scheduleKeyboardDismissFocusRestoreIfNeeded(after: 0.1)
    }

    public func chatInputTextNodeDidUpdateText() {
        self.updateComposerPrimaryActionButtons()
    }

    public func chatInputTextNodeShouldReturn(modifierFlags: UIKeyModifierFlags) -> Bool {
        if self.sendCurrentInputText() {
            return false
        }
        self.insertComposerNewline()
        return false
    }

    public func chatInputTextNodeDidChangeSelection(dueToEditing: Bool) {
    }

    public func chatInputTextNodeBackspaceWhileEmpty() {
    }

    @available(iOS 13.0, *)
    public func chatInputTextNodeMenu(forTextRange textRange: NSRange, suggestedActions: [UIMenuElement]) -> UIMenu {
        return UIMenu(children: suggestedActions)
    }

    public func chatInputTextNode(shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }

    public func chatInputTextNodeShouldCopy() -> Bool {
        return true
    }

    public func chatInputTextNodeShouldPaste() -> Bool {
        return true
    }

    public func chatInputTextNodeShouldRespondToAction(action: Selector) -> Bool {
        return true
    }

    public func chatInputTextNodeTargetForAction(action: Selector) -> ChatInputTextNode.TargetForAction? {
        return nil
    }

    // MARK: - Actions

    @objc private func backPressed() {
        self.actions.back?()
    }

    @objc private func profilePressed() {
        self.actions.openProfile?()
    }

    func voiceOverFocusProfileButton() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)
        UIAccessibility.post(notification: .screenChanged, argument: self.profileButton)
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
        _ = self.sendCurrentInputText()
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
        if self.inputTextView.isFirstResponder || self.lastKnownKeyboardOverlap > 0.0 || self.hasFirstResponderDescendant() {
            self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)
            self.endEditing(true)
            self.scheduleKeyboardDismissFocusRestoreIfNeeded(after: 0.08)
            return true
        }
        if let back = self.actions.back {
            back()
            return true
        }
        return false
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
        self.cachedVoiceOverScrollbarAccessibilityElementIndex = nil
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
        if let scrollbarElement = element as? ChatVoiceOverOverlayScrollbarAccessibilityElement, scrollbarElement.overlay === self {
            self.rebuildAccessibilityElementsIfNeeded()
            if let index = self.cachedVoiceOverScrollbarAccessibilityElementIndex {
                return index
            }
            return NSNotFound
        }
        guard let element = element as? ChatVoiceOverOverlayRowAccessibilityElement else {
            return NSNotFound
        }
        guard element.overlay === self else {
            return NSNotFound
        }
        switch element.kind {
        case .loadEarlier:
            let baseIndex = self.shouldShowLoadEarlierRow ? 0 : NSNotFound
            if baseIndex == NSNotFound {
                return NSNotFound
            }
            if let anchorRow = self.voiceOverScrollbarAccessibilityElementAnchorTableRow, baseIndex > anchorRow {
                return NSNotFound
            }
            if let scrollbarIndex = self.cachedVoiceOverScrollbarAccessibilityElementIndex, baseIndex >= scrollbarIndex {
                return baseIndex + 1
            }
            return baseIndex
        case let .row(stableId):
            guard let rowIndex = self.rowIndexByStableId[stableId] else {
                return NSNotFound
            }
            let baseIndex = rowIndex + self.loadEarlierRowOffset
            if let anchorRow = self.voiceOverScrollbarAccessibilityElementAnchorTableRow, baseIndex > anchorRow {
                return NSNotFound
            }
            if let scrollbarIndex = self.cachedVoiceOverScrollbarAccessibilityElementIndex, baseIndex >= scrollbarIndex {
                return baseIndex + 1
            }
            return baseIndex
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
                element = ChatVoiceOverOverlayRowAccessibilityElement(container: self.tableAccessibilityContainerView, overlay: self, kind: .loadEarlier)
                self.loadEarlierAccessibilityElement = element
            }
            element.overlay = self
            elements.append(element)
        } else {
            self.loadEarlierAccessibilityElement = nil
        }

        let anchorTableRow = self.voiceOverScrollbarAccessibilityElementAnchorTableRow
        let maxMessageIndexToInclude: Int? = anchorTableRow.flatMap { anchor in
            return max(-1, anchor - self.loadEarlierRowOffset)
        }
        let messageCountToInclude: Int = {
            guard let maxMessageIndexToInclude else {
                return self.rows.count
            }
            return max(0, min(self.rows.count, maxMessageIndexToInclude + 1))
        }()

        var newElementsByStableId: [UInt64: ChatVoiceOverOverlayRowAccessibilityElement] = [:]
        newElementsByStableId.reserveCapacity(messageCountToInclude)
        for index in 0 ..< messageCountToInclude {
            let row = self.rows[index]
            let element = self.rowAccessibilityElementsByStableId[row.stableId] ?? ChatVoiceOverOverlayRowAccessibilityElement(container: self.tableAccessibilityContainerView, overlay: self, kind: .row(stableId: row.stableId))
            element.overlay = self
            newElementsByStableId[row.stableId] = element
            elements.append(element)
        }
        self.rowAccessibilityElementsByStableId = newElementsByStableId

        if anchorTableRow != nil {
            self.voiceOverScrollbarAccessibilityElement.overlay = self
            elements.append(self.voiceOverScrollbarAccessibilityElement)
            self.cachedVoiceOverScrollbarAccessibilityElementIndex = elements.count - 1
        } else {
            self.cachedVoiceOverScrollbarAccessibilityElementIndex = nil
        }

        self.cachedAccessibilityElements = elements
    }

    fileprivate func setVoiceOverScrollbarAccessibilityElementActive(_ isActive: Bool, anchorTableRow: Int?) {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard !self.usesNativeVoiceOverAccessibility else {
            self.voiceOverScrollbarAccessibilityElementAnchorTableRow = nil
            self.updateComposerAccessibilityVisibility()
            return
        }
        let resolvedAnchorTableRow: Int? = isActive ? anchorTableRow : nil
        guard self.voiceOverScrollbarAccessibilityElementAnchorTableRow != resolvedAnchorTableRow else {
            return
        }
        self.voiceOverScrollbarAccessibilityElementAnchorTableRow = resolvedAnchorTableRow
        if resolvedAnchorTableRow != nil {
            self.composerView.accessibilityElementsHidden = true
            self.voicePlayerView.accessibilityElementsHidden = true
        } else {
            self.updateComposerAccessibilityVisibility()
            self.voicePlayerView.accessibilityElementsHidden = false
        }
        self.invalidateAccessibilityElements()
    }

    private func voiceOverScrollbarDidPerformAccessibilityScroll() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.voiceOverScrollbarAccessibilityElementAnchorTableRow != nil else {
            return
        }

        // Allow the scroll view to settle its visible rows before recomputing an anchor.
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            guard self.voiceOverScrollbarAccessibilityElementAnchorTableRow != nil else {
                return
            }

            let baseRowCount = max(0, self.tableView.numberOfRows(inSection: 0))
            let hasLoadEarlierRow: Bool = {
                guard let first = self.tableAccessibilityElement(at: 0) as? ChatVoiceOverOverlayRowAccessibilityElement else {
                    return false
                }
                if case .loadEarlier = first.kind {
                    return true
                } else {
                    return false
                }
            }()
            let firstMessageRow = hasLoadEarlierRow ? 1 : 0

            let resolvedAnchorRow: Int = {
                guard baseRowCount > 0 else {
                    return firstMessageRow
                }
                if self.voiceOverScrollbarIsAtBottom(visibleIndexPaths: self.voiceOverScrollbarVisibleIndexPathsSorted()) {
                    return max(firstMessageRow, baseRowCount - 1)
                }
                if self.voiceOverScrollbarIsAtTop(visibleIndexPaths: self.voiceOverScrollbarVisibleIndexPathsSorted()) {
                    return firstMessageRow
                }
                if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.sorted(), !visibleIndexPaths.isEmpty {
                    let candidates = visibleIndexPaths.filter { $0.section == 0 && $0.row >= firstMessageRow }
                    let effectiveCandidates = candidates.isEmpty ? visibleIndexPaths : candidates
                    let visibleMidY = self.tableView.contentOffset.y + self.tableView.bounds.height * 0.5
                    var best = effectiveCandidates[0]
                    var bestDistance = abs(self.tableView.rectForRow(at: best).midY - visibleMidY)
                    for indexPath in effectiveCandidates.dropFirst() {
                        let distance = abs(self.tableView.rectForRow(at: indexPath).midY - visibleMidY)
                        if distance < bestDistance {
                            bestDistance = distance
                            best = indexPath
                        }
                    }
                    return max(firstMessageRow, min(baseRowCount - 1, best.row))
                }
                return max(firstMessageRow, min(baseRowCount - 1, baseRowCount / 2))
            }()

            self.setVoiceOverScrollbarAccessibilityElementActive(true, anchorTableRow: resolvedAnchorRow)
        }
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

    fileprivate func voiceOverPresentationStrings() -> PresentationStrings {
        return self.interfaceState?.strings ?? defaultPresentationStrings
    }

    fileprivate func voiceOverAccessibilityContainerHitTest(pointInContainerSpace point: CGPoint) -> Any? {
        guard UIAccessibility.isVoiceOverRunning else {
            return nil
        }

        let containerBounds = self.tableAccessibilityContainerView.bounds
        let gutterWidth = ChatVoiceOverOverlayTableView.voiceOverScrollbarGutterWidth
        let isInGutter = point.x >= containerBounds.maxX - gutterWidth

        let tablePoint = self.tableView.convert(point, from: self.tableAccessibilityContainerView)

        if isInGutter {
            let baseRowCount = max(0, self.tableView.numberOfRows(inSection: 0))
            let listPoint = CGPoint(
                x: max(self.tableView.bounds.minX + 1.0, self.tableView.bounds.maxX - gutterWidth - 6.0),
                y: tablePoint.y
            )
            let anchorRow: Int? = {
                if let indexPath = self.tableView.indexPathForRow(at: listPoint), indexPath.section == 0 {
                    return indexPath.row
                }
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
                return nearestIndexPath?.row
            }()

            let hasLoadEarlierRow: Bool = {
                guard let first = self.tableAccessibilityElement(at: 0) as? ChatVoiceOverOverlayRowAccessibilityElement else {
                    return false
                }
                if case .loadEarlier = first.kind {
                    return true
                } else {
                    return false
                }
            }()
            let firstMessageRow = hasLoadEarlierRow ? 1 : 0
            let resolvedAnchorRow: Int = {
                guard baseRowCount > 0 else {
                    return firstMessageRow
                }
                let lastRow = max(0, baseRowCount - 1)
                let hasMessageRows = baseRowCount > firstMessageRow

                let minOffset = -self.tableView.adjustedContentInset.top
                let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
                if maxOffset - self.tableView.contentOffset.y <= 1.0 {
                    return lastRow
                }
                if self.tableView.contentOffset.y - minOffset <= 1.0 {
                    return hasMessageRows ? firstMessageRow : lastRow
                }

                let fallback = max(firstMessageRow, baseRowCount / 2)
                return max(firstMessageRow, min(baseRowCount - 1, anchorRow ?? fallback))
            }()

            self.setVoiceOverScrollbarAccessibilityElementActive(true, anchorTableRow: resolvedAnchorRow)
            return self.voiceOverScrollbarAccessibilityElement
        }

        if let indexPath = self.tableView.indexPathForRow(at: tablePoint), let element = self.accessibilityElement(at: indexPath) {
            return element
        }

        // If the user explores between rows, fall back to the nearest visible row.
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
        if let nearestIndexPath, let element = self.accessibilityElement(at: nearestIndexPath) {
            return element
        }

        return nil
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
        let rect = self.tableView.rectForRow(at: indexPath)
        return self.tableView.convert(rect, to: self.tableAccessibilityContainerView)
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

    fileprivate func voiceOverScrollbarAccessibilityFrameInContainerSpace() -> CGRect {
        let bounds = self.tableAccessibilityContainerView.bounds
        let width = ChatVoiceOverOverlayTableView.voiceOverScrollbarGutterWidth
        return CGRect(x: bounds.maxX - width, y: bounds.minY, width: width, height: bounds.height)
    }

    fileprivate func voiceOverScrollbarAccessibilityFrameInScreenSpace() -> CGRect {
        return self.tableAccessibilityContainerView.convert(self.voiceOverScrollbarAccessibilityFrameInContainerSpace(), to: nil)
    }

    fileprivate func voiceOverScrollbarAccessibilityLabel() -> String? {
        return self.interfaceState?.strings.DialogList_SearchSectionMessages ?? defaultPresentationStrings.DialogList_SearchSectionMessages
    }

    fileprivate func voiceOverScrollbarAccessibilityHint() -> String? {
        return self.interfaceState?.strings.SharedMedia_FastScrollTooltip ?? defaultPresentationStrings.SharedMedia_FastScrollTooltip
    }

    fileprivate func voiceOverScrollbarAccessibilityValue() -> String? {
        let visibleIndexPaths = self.voiceOverScrollbarVisibleIndexPathsSorted()
        let rawPercent = self.voiceOverScrollbarRawDisplayPercent(visibleIndexPaths: visibleIndexPaths)
        let step = max(1, Self.voiceOverScrollbarPercentStep)
        let quantized = Int((rawPercent / CGFloat(step)).rounded()) * step
        let percent = max(0, min(100, quantized))
        return "\(percent)%"
    }

    fileprivate func voiceOverScrollbarAccessibilityIncrement() {
        // Match the native iOS VoiceOver scrollbar behavior:
        // - swipe up (increment) scrolls up (towards older messages), which decreases the percentage.
        self.voiceOverScrollbarAccessibilityAdjustPercent(by: -Self.voiceOverScrollbarPercentStep)
    }

    fileprivate func voiceOverScrollbarAccessibilityDecrement() {
        // - swipe down (decrement) scrolls down (towards newer messages), which increases the percentage.
        self.voiceOverScrollbarAccessibilityAdjustPercent(by: Self.voiceOverScrollbarPercentStep)
    }

    private func voiceOverScrollbarAccessibilityAdjustPercent(by percentDelta: Int) {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        let visibleIndexPaths = self.voiceOverScrollbarVisibleIndexPathsSorted()
        let rawPercent = self.voiceOverScrollbarRawDisplayPercent(visibleIndexPaths: visibleIndexPaths)
        let step = max(1, Self.voiceOverScrollbarPercentStep)
        let currentQuantized = Int((rawPercent / CGFloat(step)).rounded()) * step

        let targetDisplayPercent = max(0, min(100, currentQuantized + percentDelta))

        let minOffset = -self.tableView.adjustedContentInset.top
        let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
        let range = maxOffset - minOffset
        guard range > 1.0 else {
            return
        }

        self.noteVoiceOverNavigationActivity()
        UIView.performWithoutAnimation {
            if targetDisplayPercent <= 0 {
                self.scrollToTop(animated: false)
            } else if targetDisplayPercent >= 100 {
                self.scrollToBottom(animated: false)
            } else {
                let targetProgress = CGFloat(targetDisplayPercent) / 100.0
                let targetOffset = minOffset + targetProgress * range
                let clampedOffset = self.clampContentOffsetY(targetOffset)
                self.tableView.setContentOffset(CGPoint(x: self.tableView.contentOffset.x, y: clampedOffset), animated: false)
            }
            self.tableView.layoutIfNeeded()
        }

        // At 100%, always keep the last message in the swipe order so swipe-left lands on it (not the penultimate).
        if targetDisplayPercent >= 100 {
            let baseRowCount = max(0, self.tableView.numberOfRows(inSection: 0))
            if baseRowCount > 0 {
                self.setVoiceOverScrollbarAccessibilityElementActive(true, anchorTableRow: baseRowCount - 1)
            }
        }

        let announcedValue = self.voiceOverScrollbarAccessibilityValue()
        UIAccessibility.post(notification: .pageScrolled, argument: announcedValue)
        self.voiceOverScrollbarDidPerformAccessibilityScroll()
    }

    private func voiceOverScrollbarRawPercentFromContentOffset() -> CGFloat {
        let minOffset = -self.tableView.adjustedContentInset.top
        let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
        let range = maxOffset - minOffset
        guard range > 1.0 else {
            return 100.0
        }

        let progressFromTop = (self.tableView.contentOffset.y - minOffset) / range
        let clamped = max(0.0, min(1.0, progressFromTop))
        return clamped * 100.0
    }

    private func voiceOverScrollbarVisibleIndexPathsSorted() -> [IndexPath] {
        return self.tableView.indexPathsForVisibleRows?.sorted() ?? []
    }

    private func voiceOverScrollbarIsAtTop(visibleIndexPaths: [IndexPath]) -> Bool {
        if visibleIndexPaths.contains(where: { $0.section == 0 && $0.row == 0 }) {
            return true
        }
        let minOffset = -self.tableView.adjustedContentInset.top
        return self.tableView.contentOffset.y - minOffset <= 1.0
    }

    private func voiceOverScrollbarIsAtBottom(visibleIndexPaths: [IndexPath]) -> Bool {
        let rowCount = max(0, self.tableView.numberOfRows(inSection: 0))
        guard rowCount > 0 else {
            return true
        }
        if visibleIndexPaths.contains(where: { $0.section == 0 && $0.row == rowCount - 1 }) {
            return true
        }
        let minOffset = -self.tableView.adjustedContentInset.top
        let maxOffset = max(minOffset, self.tableView.contentSize.height - self.tableView.bounds.height + self.tableView.adjustedContentInset.bottom)
        return maxOffset - self.tableView.contentOffset.y <= 1.0
    }

    private func voiceOverScrollbarRawDisplayPercent(visibleIndexPaths: [IndexPath]) -> CGFloat {
        let percentFromOffset = self.voiceOverScrollbarRawPercentFromContentOffset()
        var display = percentFromOffset

        if self.voiceOverScrollbarIsAtBottom(visibleIndexPaths: visibleIndexPaths) {
            display = 100.0
        } else if self.voiceOverScrollbarIsAtTop(visibleIndexPaths: visibleIndexPaths) {
            display = 0.0
        }

        return max(0.0, min(100.0, display))
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
            return self.activateMessageRow(message)
        }
    }

    private func pollMedia(in message: Message) -> TelegramMediaPoll? {
        for media in message.media {
            if let poll = media as? TelegramMediaPoll {
                return poll
            }
        }
        return nil
    }

    private func todoMedia(in message: Message) -> TelegramMediaTodo? {
        for media in message.media {
            if let todo = media as? TelegramMediaTodo {
                return todo
            }
        }
        return nil
    }

    private func isVoiceMessage(_ message: Message) -> Bool {
        for media in message.media {
            if let file = media as? TelegramMediaFile, file.isVoice {
                return true
            }
        }
        return false
    }

    private static func formatPlaybackTimestamp(_ seconds: Double) -> String {
        let totalSeconds = max(Int32(0), Int32(seconds.rounded()))
        let hours = totalSeconds / 3600
        let minutes = totalSeconds / 60 % 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func updateVoicePlayerControls() {
        let state = self.interfaceState
        let strings = state?.strings ?? defaultPresentationStrings

        guard let playbackState = self.voicePlaybackState else {
            self.voicePlayerSeekWorkItem?.cancel()
            self.voicePlayerSeekWorkItem = nil
            self.voicePlayerHeightConstraint?.constant = 0.0
            self.voicePlayerView.isHidden = true
            self.voicePlayerView.isUserInteractionEnabled = false
            return
        }

        self.voicePlayerHeightConstraint?.constant = 56.0
        self.voicePlayerView.isHidden = false
        self.voicePlayerView.isUserInteractionEnabled = true

        let isPlaying = playbackState.isPlaying
        let playPauseImageName = isPlaying ? "pause.fill" : "play.fill"
        self.voicePlayerPlayPauseButton.setImage(UIImage(systemName: playPauseImageName), for: .normal)
        self.voicePlayerPlayPauseButton.accessibilityLabel = isPlaying ? strings.VoiceOver_Media_PlaybackPause : strings.VoiceOver_Media_PlaybackPlay
        self.voicePlayerPlayPauseButton.accessibilityTraits = [.button, .startsMediaSession]

        let duration = max(0.0, playbackState.duration)
        let position = max(0.0, min(duration, playbackState.position))

        self.isUpdatingVoicePlayerSlider = true
        self.voicePlayerPositionSlider.minimumValue = 0.0
        self.voicePlayerPositionSlider.maximumValue = Float(max(1.0, duration))
        self.voicePlayerPositionSlider.value = Float(position)
        self.isUpdatingVoicePlayerSlider = false

        let bundle = getAppBundle()
        self.voicePlayerPositionSlider.accessibilityLabel = bundle.localizedString(forKey: "VoiceOver.Media.PlaybackPosition", value: "Playback position", table: nil)
        self.voicePlayerPositionSlider.accessibilityHint = nil
        self.voicePlayerPositionSlider.accessibilityValue = "\(Self.formatPlaybackTimestamp(position)) / \(Self.formatPlaybackTimestamp(duration))"

        let rate = AudioPlaybackRate(playbackState.baseRate)
        self.voicePlayerSpeedButton.setTitle(rate.stringValue, for: .normal)
        self.voicePlayerSpeedButton.accessibilityLabel = strings.VoiceOver_Media_PlaybackRate
        self.voicePlayerSpeedButton.accessibilityHint = strings.VoiceOver_Media_PlaybackRateChange
        self.voicePlayerSpeedButton.accessibilityValue = rate.stringValue
        self.voicePlayerSpeedButton.accessibilityTraits = [.button]

        self.voicePlayerPlayPauseButton.tintColor = state?.theme.rootController.navigationBar.accentTextColor ?? tintColor
        self.voicePlayerSpeedButton.tintColor = state?.theme.rootController.navigationBar.accentTextColor ?? tintColor
        self.voicePlayerPositionSlider.tintColor = state?.theme.list.itemAccentColor ?? tintColor
    }

    private func nextVoicePlaybackRate(current: AudioPlaybackRate) -> AudioPlaybackRate {
        switch current {
        case .x0_5, .x2:
            return .x1
        case .x1:
            return .x1_5
        case .x1_5:
            return .x2
        default:
            if current.doubleValue < 0.5 {
                return .x0_5
            } else if current.doubleValue < 1.0 {
                return .x1
            } else if current.doubleValue < 1.5 {
                return .x1_5
            } else if current.doubleValue < 2.0 {
                return .x2
            } else {
                return .x1
            }
        }
    }

    @objc private func voicePlayerPlayPausePressed() {
        self.actions.toggleCurrentVoicePlayback?()
    }

    @objc private func voicePlayerSpeedPressed() {
        guard let state = self.voicePlaybackState else {
            return
        }
        let current = AudioPlaybackRate(state.baseRate)
        let next = self.nextVoicePlaybackRate(current: current)
        self.actions.setCurrentVoicePlaybackRate?(next.doubleValue)
    }

    @objc private func voicePlayerSliderValueChanged() {
        guard !self.isUpdatingVoicePlayerSlider else {
            return
        }
        let targetPosition = Double(self.voicePlayerPositionSlider.value)
        self.voicePlayerSeekWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.actions.seekCurrentVoicePlayback?(targetPosition)
        }
        self.voicePlayerSeekWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
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

    fileprivate func voiceOverAccessibilityValue(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> String? {
        guard case .row = element.kind, let row = self.row(for: element) else {
            return nil
        }
        guard case let .message(message) = row.kind else {
            return nil
        }
        return self.transcriptAccessibilityValue(for: message)
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
            var traits = resolved.traits
            if case let .message(message) = row.kind, self.isMessageActivatable(message) {
                traits.insert(.button)
            }
            return traits
        }
    }

    fileprivate func voiceOverAccessibilityCustomActions(for element: ChatVoiceOverOverlayRowAccessibilityElement) -> [UIAccessibilityCustomAction]? {
        guard let state = self.interfaceState else {
            return nil
        }
        switch element.kind {
        case .loadEarlier:
            var actions: [UIAccessibilityCustomAction] = []
            if let chatInfoAction = self.makeChatInfoAccessibilityCustomAction() {
                actions.append(chatInfoAction)
            }
            #if DEBUG
            let debugTitle = "Speak debug state"
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
            #endif
            return actions.isEmpty ? nil : actions
        case .row:
            guard let row = self.row(for: element) else {
                return nil
            }
            guard case let .message(message) = row.kind else {
                return nil
            }
            var customActions = self.makeMessageAccessibilityCustomActions(message: message, state: state, menuRectProvider: { [weak self] in
                guard let self, let indexPath = self.indexPath(for: element) else {
                    return nil
                }
                return self.tableView.convert(self.tableView.rectForRow(at: indexPath), to: self)
            })
            if let chatInfoAction = self.makeChatInfoAccessibilityCustomAction() {
                customActions.append(chatInfoAction)
            }
            return customActions.isEmpty ? nil : customActions
        }
    }

    fileprivate func voiceOverScrollbarAccessibilityCustomActions() -> [UIAccessibilityCustomAction]? {
        guard let chatInfoAction = self.makeChatInfoAccessibilityCustomAction() else {
            return nil
        }
        return [chatInfoAction]
    }

    private func makeChatInfoAccessibilityCustomAction() -> UIAccessibilityCustomAction? {
        guard let state = self.interfaceState else {
            return nil
        }
        guard self.actions.openProfile != nil else {
            return nil
        }
        return UIAccessibilityCustomAction(name: state.strings.KeyCommand_ChatInfo, actionHandler: { [weak self] _ in
            guard let self else {
                return false
            }
            self.actions.openProfile?()
            return true
        })
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
        }
        self.pendingEntries = nil
        self.applyEntries(entries)
    }

	    private func applyEntries(_ entries: [ChatHistoryEntry]) {
	        self.reconcileVoiceOverScrollbarFocusIfNeeded()

	        let incomingRows = self.makeRows(from: entries)
	        let newRows = self.mergeRows(existing: self.rows, incoming: incomingRows)
            self.messageTextActionItemsCache.removeAll(keepingCapacity: true)
	        let now = CACurrentMediaTime()

        let previousWasAtBottom = self.isAtBottom()
        self.updateShouldFollowLatestFromFocus()
        let shouldPinToLatest = previousWasAtBottom && self.shouldFollowLatest
        let previousWasWaitingForLoadEarlier = self.isWaitingForLoadEarlier
        let previousWasLoadEarlierInProgress = previousWasWaitingForLoadEarlier || self.isLoadingEarlierHistory
        let shouldSuppressVoiceOverFocusRestoration = UIAccessibility.isVoiceOverRunning && !previousWasLoadEarlierInProgress && self.isVoiceOverNavigationInProgress(graceInterval: 0.45)
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
            self.lastEntriesApplyTimestamp = now
            self.lastApplyWasStableIdsOnly = true

            // Keep UI updates lightweight for progress-only refreshes (e.g. uploads).
            // The accessibility labels/hints are computed dynamically from `self.rows`,
            // so we don't need to rebuild accessibility elements on every update.
            if now - self.lastStableIdsOnlyVisibleReloadTimestamp > 0.25 {
                self.lastStableIdsOnlyVisibleReloadTimestamp = now
                self.reloadVisibleRows(excluding: focusedCellIndexPathBeforeUpdate)
            }
            if self.forceScrollToBottomOnNextApply {
                self.forceScrollToBottomOnNextApply = false
                if shouldPinToLatest {
                    self.scrollToBottom(animated: false)
                }
            }
            if self.refreshControl.isRefreshing, !previousWasWaitingForLoadEarlier {
                self.refreshControl.endRefreshing()
            }
            self.scheduleVoiceOverFocusRecoveryIfNeeded()
            return
        }

        self.lastEntriesApplyTimestamp = now
        self.lastApplyWasStableIdsOnly = false

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

        if UIAccessibility.isVoiceOverRunning, !shouldSuppressVoiceOverFocusRestoration {
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

                        if let target = self.accessibilityFocusTarget(at: focusTargetIndexPath) {
                            UIAccessibility.post(notification: .layoutChanged, argument: target)
                        } else {
                            UIAccessibility.post(notification: .layoutChanged, argument: self.tableView)
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

        if UIAccessibility.isVoiceOverRunning, !didReloadTable, focusedCellIndexPathBeforeUpdate != nil {
            let focusRebindIndexPath: IndexPath? = {
                if let focusedMessageAnchorBeforeUpdate, let index = self.indexOfRow(for: focusedMessageAnchorBeforeUpdate) {
                    return IndexPath(row: index + self.loadEarlierRowOffset, section: 0)
                }
                if let focusedCellIndexPathBeforeUpdate, focusedCellIndexPathBeforeUpdate.section == 0 {
                    return focusedCellIndexPathBeforeUpdate
                }
                return nil
            }()

            if let focusRebindIndexPath {
                DispatchQueue.main.async { [weak self] in
                    guard let self else {
                        return
                    }
                    guard UIAccessibility.isVoiceOverRunning else {
                        return
                    }

                    // Avoid stealing focus if VoiceOver is still inside the chat overlay.
                    let focusedNow = UIAccessibility.focusedElement(using: .notificationVoiceOver)
                    if let focusedRow = focusedNow as? ChatVoiceOverOverlayRowAccessibilityElement, focusedRow.overlay === self {
                        return
                    }
                    if let focusedView = focusedNow as? UIView, focusedView.isDescendant(of: self) {
                        return
                    }

                    if let target = self.accessibilityFocusTarget(at: focusRebindIndexPath) {
                        UIAccessibility.post(notification: .layoutChanged, argument: target)
                    } else {
                        UIAccessibility.post(notification: .layoutChanged, argument: self.tableView)
                    }
                }
            }
        }

        self.scheduleVoiceOverFocusRecoveryIfNeeded()

        if didLoadEarlierProgress {
            self.loadEarlierInitiationFocus = nil
        }

        self.requestVisibleTranslationsIfNeeded()
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

    private func isVoiceOverElementWithinOverlay(_ focusedElement: Any?) -> Bool {
        guard let focusedElement else {
            return false
        }
        if let focusedView = focusedElement as? UIView {
            return focusedView.isDescendant(of: self)
        }
        if let focusedRow = focusedElement as? ChatVoiceOverOverlayRowAccessibilityElement {
            return focusedRow.overlay === self
        }
        if let focusedScrollbar = focusedElement as? ChatVoiceOverOverlayScrollbarAccessibilityElement {
            return focusedScrollbar.overlay === self
        }
        if let focusedAccessibilityElement = focusedElement as? UIAccessibilityElement,
           let containerView = focusedAccessibilityElement.accessibilityContainer as? UIView {
            return containerView.isDescendant(of: self)
        }
        return false
    }

    private func isVoiceOverFocusWithinOverlay() -> Bool {
        guard UIAccessibility.isVoiceOverRunning else {
            return false
        }
        return self.isVoiceOverElementWithinOverlay(UIAccessibility.focusedElement(using: .notificationVoiceOver))
    }

    @discardableResult
    private func sendCurrentInputText() -> Bool {
        guard self.isComposerEnabled else {
            return false
        }
        let text = self.inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return false
        }
        self.actions.sendText?(text)
        self.inputTextView.text = ""
        self.updateComposerPrimaryActionButtons()
        return true
    }

    private func insertComposerNewline() {
        self.inputTextView.insertText("\n")
        self.updateComposerPrimaryActionButtons()
    }

    private func preferredComposerFocusTarget() -> Any? {
        guard !self.composerView.accessibilityElementsHidden, self.isComposerEnabled else {
            return nil
        }
        if !self.sendButton.isHidden, self.sendButton.isAccessibilityElement, self.sendButton.isEnabled {
            return self.sendButton
        }
        if !self.recordButton.isHidden, self.recordButton.isAccessibilityElement, self.recordButton.isEnabled {
            return self.recordButton
        }
        if self.attachButton.isAccessibilityElement, self.attachButton.isEnabled {
            return self.attachButton
        }
        return self.inputTextView
    }

    private func preferredVoiceOverRecoveryTarget() -> Any {
        if let composerTarget = self.preferredComposerFocusTarget() {
            return composerTarget
        }
        if let targetIndexPath = self.voiceOverFallbackFocusIndexPath(), let target = self.accessibilityFocusTarget(at: targetIndexPath) {
            return target
        }
        return self.profileButton
    }

    private func accessibilityFocusTarget(at indexPath: IndexPath) -> Any? {
        if self.usesNativeVoiceOverAccessibility {
            if self.tableView.indexPathsForVisibleRows?.contains(indexPath) != true {
                return self.tableView
            }
            return self.tableView.cellForRow(at: indexPath) ?? self.tableView
        } else {
            return self.accessibilityElement(at: indexPath) ?? self.tableView
        }
    }

    public var shouldPreserveModalIsolationDuringFocusRecovery: Bool {
        guard UIAccessibility.isVoiceOverRunning else {
            return false
        }
        return CACurrentMediaTime() < self.voiceOverModalIsolationGraceDeadline
    }

    private func extendVoiceOverModalIsolationGrace(_ duration: TimeInterval) {
        let deadline = CACurrentMediaTime() + max(0.0, duration)
        if deadline > self.voiceOverModalIsolationGraceDeadline {
            self.voiceOverModalIsolationGraceDeadline = deadline
        }
    }

    private func shouldForceVoiceOverFocusRestore(to target: Any) -> Bool {
        guard UIAccessibility.isVoiceOverRunning else {
            return false
        }
        let focusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver)
        guard let focusedElement else {
            return true
        }

        if let targetView = target as? UIView, let focusedView = focusedElement as? UIView {
            if focusedView === targetView {
                return false
            }
            if focusedView.isDescendant(of: targetView) {
                return false
            }
            if focusedView === self.inputTextView || focusedView.isDescendant(of: self.inputTextView) {
                return true
            }
            if !focusedView.isDescendant(of: self) {
                return true
            }
            return false
        }

        if let focusedRow = focusedElement as? ChatVoiceOverOverlayRowAccessibilityElement {
            return focusedRow.overlay !== self
        }
        if let focusedScrollbar = focusedElement as? ChatVoiceOverOverlayScrollbarAccessibilityElement {
            return focusedScrollbar.overlay !== self
        }
        if let focusedAccessibilityElement = focusedElement as? UIAccessibilityElement,
           let containerView = focusedAccessibilityElement.accessibilityContainer as? UIView {
            if let targetView = target as? UIView, containerView === targetView || containerView.isDescendant(of: targetView) {
                return false
            }
            if containerView === self.inputTextView || containerView.isDescendant(of: self.inputTextView) {
                return true
            }
            return !containerView.isDescendant(of: self)
        }

        return true
    }

    private func hasFirstResponderDescendant() -> Bool {
        return self.findFirstResponder(in: self) != nil
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        for subview in view.subviews {
            if let responder = self.findFirstResponder(in: subview) {
                return responder
            }
        }
        return nil
    }

    private func scheduleKeyboardDismissFocusRestoreIfNeeded(after delay: TimeInterval, remainingAttempts: Int = 3) {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }

        self.extendVoiceOverModalIsolationGrace(max(1.2, delay + 1.0))

        self.keyboardDismissFocusRestoreWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            self.keyboardDismissFocusRestoreWorkItem = nil

            guard UIAccessibility.isVoiceOverRunning else {
                return
            }
            guard self.window != nil, !self.accessibilityElementsHidden, self.accessibilityViewIsModal else {
                return
            }

            self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)

            let focusTarget = self.preferredVoiceOverRecoveryTarget()

            if self.shouldForceVoiceOverFocusRestore(to: focusTarget) {
                UIAccessibility.post(notification: .screenChanged, argument: focusTarget)
                DispatchQueue.main.async {
                    UIAccessibility.post(notification: .layoutChanged, argument: focusTarget)
                }
            }

            guard remainingAttempts > 1 else {
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                guard let self else {
                    return
                }
                guard UIAccessibility.isVoiceOverRunning else {
                    return
                }
                guard self.window != nil, !self.accessibilityElementsHidden, self.accessibilityViewIsModal else {
                    return
                }
                guard self.shouldForceVoiceOverFocusRestore(to: focusTarget) else {
                    return
                }
                self.scheduleKeyboardDismissFocusRestoreIfNeeded(after: 0.0, remainingAttempts: remainingAttempts - 1)
            }
        }

        self.keyboardDismissFocusRestoreWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func scheduleVoiceOverFocusRecoveryIfNeeded() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.window != nil, !self.accessibilityElementsHidden, self.accessibilityViewIsModal else {
            return
        }
        self.extendVoiceOverModalIsolationGrace(1.2)
        guard self.voiceOverFocusRecoveryWorkItem == nil else {
            return
        }

        let focusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver)
        guard focusedElement == nil || !self.isVoiceOverElementWithinOverlay(focusedElement) else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            self.voiceOverFocusRecoveryWorkItem = nil

            guard UIAccessibility.isVoiceOverRunning else {
                return
            }
            guard self.window != nil, !self.accessibilityElementsHidden, self.accessibilityViewIsModal else {
                return
            }

            let currentFocusedElement = UIAccessibility.focusedElement(using: .notificationVoiceOver)
            guard currentFocusedElement == nil || !self.isVoiceOverElementWithinOverlay(currentFocusedElement) else {
                return
            }

            // In some transitions (e.g. returning from system pickers or after keyboard dismissal),
            // VoiceOver can lose focus or jump outside this modal overlay.
            self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)

            let recoveryTarget = self.preferredVoiceOverRecoveryTarget()
            UIAccessibility.post(notification: .screenChanged, argument: recoveryTarget)
            DispatchQueue.main.async {
                UIAccessibility.post(notification: .layoutChanged, argument: recoveryTarget)
            }
        }

        self.voiceOverFocusRecoveryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

	    private func reconcileVoiceOverScrollbarFocusIfNeeded() {
	        guard UIAccessibility.isVoiceOverRunning else {
	            return
	        }
	        guard self.voiceOverScrollbarAccessibilityElementAnchorTableRow != nil else {
	            return
	        }

	        if let focusedScrollbar = UIAccessibility.focusedElement(using: .notificationVoiceOver) as? ChatVoiceOverOverlayScrollbarAccessibilityElement,
	           focusedScrollbar.overlay === self
	        {
	            return
	        }

	        self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)
	    }

	    private func voiceOverFallbackFocusIndexPath() -> IndexPath? {
	        let rowCount = max(0, self.tableView.numberOfRows(inSection: 0))
	        guard rowCount > 0 else {
	            return nil
        }

        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.sorted(), !visibleIndexPaths.isEmpty else {
            return IndexPath(row: max(0, rowCount - 1), section: 0)
        }

        let firstMessageRow = self.loadEarlierRowOffset
        let candidates = visibleIndexPaths.filter { $0.section == 0 && $0.row >= firstMessageRow }
        let effectiveCandidates = candidates.isEmpty ? visibleIndexPaths : candidates

        if self.isAtBottom() {
            return effectiveCandidates.last
        }
        if self.isNearTop() {
            return effectiveCandidates.first
        }

        let visibleMidY = self.tableView.contentOffset.y + self.tableView.bounds.height * 0.5
        var best = effectiveCandidates[0]
        var bestDistance = abs(self.tableView.rectForRow(at: best).midY - visibleMidY)
        for indexPath in effectiveCandidates.dropFirst() {
            let distance = abs(self.tableView.rectForRow(at: indexPath).midY - visibleMidY)
            if distance < bestDistance {
                bestDistance = distance
                best = indexPath
            }
        }
        return best
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
        case .unreadMarker:
            let title = state.strings.Conversation_UnreadMessages
            return (title, nil, title, nil, [.staticText, .header])
        case let .info(text):
            let title = text
            return (title, nil, title, nil, [.staticText])
        }
    }

    private func resolveMessageRow(message: Message, state: ChatPresentationInterfaceState) -> (title: String, subtitle: String?, accessibilityLabel: String, hint: String?, traits: UIAccessibilityTraits) {
        let isIncoming = message.effectivelyIncoming(state.accountPeerId)
        let textActionItems = self.messageTextActionItems(for: message)
        let translatedText = self.translatedMessageText(for: message, state: state)

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
        if let translatedText, !translatedText.isEmpty {
            title = translatedText
        }
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
            if let poll = media as? TelegramMediaPoll {
                traits.insert(.button)

                let typeText: String = {
                    if poll.isClosed {
                        return state.strings.MessagePoll_LabelClosed
                    }
                    switch poll.kind {
                    case .quiz:
                        if case .anonymous = poll.publicity {
                            return state.strings.MessagePoll_LabelAnonymousQuiz
                        } else {
                            return state.strings.MessagePoll_LabelQuiz
                        }
                    case .poll:
                        if case .anonymous = poll.publicity {
                            return state.strings.MessagePoll_LabelAnonymous
                        } else {
                            return state.strings.MessagePoll_LabelPoll
                        }
                    }
                }()

                let totalVoters = poll.results.totalVoters ?? 0
                let votesText: String
                if totalVoters > 0 {
                    votesText = state.strings.VoiceOver_Chat_PollVotes(Int32(totalVoters))
                } else {
                    votesText = state.strings.VoiceOver_Chat_PollNoVotes
                }

                let question = (translatedText ?? poll.text).trimmingCharacters(in: .whitespacesAndNewlines)
                let optionCountText = state.strings.VoiceOver_Chat_PollOptionCount(Int32(poll.options.count))

                var baseLabel = ""
                baseLabel.append(typeText)
                if !question.isEmpty {
                    baseLabel.append(". ")
                    baseLabel.append(question)
                }
                baseLabel.append(". ")
                baseLabel.append(optionCountText)
                baseLabel.append(". ")
                baseLabel.append(votesText)
                if poll.isClosed {
                    baseLabel.append(". ")
                    baseLabel.append(state.strings.VoiceOver_Chat_PollFinalResults)
                }

                if isIncoming, announceIncomingAuthors, let authorName {
                    accessibilityLabel = "\(authorName). \(baseLabel)"
                } else if !isIncoming {
                    accessibilityLabel = "\(state.strings.DialogList_You). \(baseLabel)"
                } else {
                    accessibilityLabel = baseLabel
                }

                hint = state.strings.VoiceOver_Chat_OpenHint
                return (question.isEmpty ? typeText : question, subtitle, accessibilityLabel, hint, traits)
            } else if let todo = media as? TelegramMediaTodo {
                traits.insert(.button)

                let typeText: String = {
                    if todo.flags.contains(.othersCanComplete) {
                        return state.strings.Chat_Todo_Message_TitleGroup
                    } else if let author = message.author, author.id != state.accountPeerId {
                        return state.strings.Chat_Todo_Message_TitlePersonal(EnginePeer(author).compactDisplayTitle).string
                    } else {
                        return state.strings.Chat_Todo_Message_Title
                    }
                }()

                let completionSummary: String = {
                    let completionsCount = Int32(todo.completions.count)
                    let format: String
                    if let author = message.author, author.id != state.accountPeerId, !todo.flags.contains(.othersCanComplete) {
                        format = state.strings.Chat_Todo_Message_CompletedBy(completionsCount).replacingOccurrences(of: "{name}", with: EnginePeer(author).compactDisplayTitle)
                    } else {
                        format = state.strings.Chat_Todo_Message_Completed(completionsCount)
                    }
                    return format.replacingOccurrences(of: "{count}", with: "\(todo.items.count)")
                }()

                let todoTitle = (translatedText ?? todo.text).trimmingCharacters(in: .whitespacesAndNewlines)

                var baseLabel = ""
                baseLabel.append(typeText)
                if !todoTitle.isEmpty {
                    baseLabel.append(". ")
                    baseLabel.append(todoTitle)
                }
                if !completionSummary.isEmpty {
                    baseLabel.append(". ")
                    baseLabel.append(completionSummary)
                }

                if isIncoming, announceIncomingAuthors, let authorName {
                    accessibilityLabel = "\(authorName). \(baseLabel)"
                } else if !isIncoming {
                    accessibilityLabel = "\(state.strings.DialogList_You). \(baseLabel)"
                } else {
                    accessibilityLabel = baseLabel
                }

                hint = state.strings.VoiceOver_Chat_OpenHint
                return (todoTitle.isEmpty ? typeText : todoTitle, subtitle, accessibilityLabel, hint, traits)
            } else if let contact = media as? TelegramMediaContact {
                traits.insert(.button)

                let typeText: String
                if isIncoming {
                    if announceIncomingAuthors, let authorName {
                        typeText = state.strings.VoiceOver_Chat_ContactFrom(authorName).string
                    } else {
                        typeText = state.strings.VoiceOver_Chat_Contact
                    }
                } else {
                    typeText = state.strings.VoiceOver_Chat_YourContact
                }

                var displayName = ""
                if !contact.firstName.isEmpty {
                    displayName.append(contact.firstName)
                }
                if !contact.lastName.isEmpty {
                    if !displayName.isEmpty {
                        displayName.append(" ")
                    }
                    displayName.append(contact.lastName)
                }
                if displayName.isEmpty {
                    displayName = state.strings.VoiceOver_Chat_Contact
                }

                var baseLabel = ""
                baseLabel.append(typeText)
                baseLabel.append(". ")
                baseLabel.append(displayName)
                if !contact.phoneNumber.isEmpty {
                    baseLabel.append(". ")
                    baseLabel.append(state.strings.VoiceOver_Chat_ContactPhoneNumber)
                    baseLabel.append(": ")
                    baseLabel.append(contact.phoneNumber)
                }

                accessibilityLabel = baseLabel
                hint = state.strings.VoiceOver_Chat_OpenHint
                return (displayName, subtitle, accessibilityLabel, hint, traits)
            } else if let map = media as? TelegramMediaMap {
                traits.insert(.button)

                let typeText = state.strings.Attachment_Location

                var baseLabel = ""
                baseLabel.append(typeText)

                if let venue = map.venue {
                    if !venue.title.isEmpty {
                        baseLabel.append(". ")
                        baseLabel.append(venue.title)
                    }
                    if let venueAddress = venue.address, !venueAddress.isEmpty {
                        baseLabel.append(". ")
                        baseLabel.append(venueAddress)
                    }
                } else if let address = map.address {
                    var parts: [String] = []
                    if let street = address.street, !street.isEmpty { parts.append(street) }
                    if let city = address.city, !city.isEmpty { parts.append(city) }
                    if let state = address.state, !state.isEmpty { parts.append(state) }
                    if !address.country.isEmpty { parts.append(address.country) }
                    if !parts.isEmpty {
                        baseLabel.append(". ")
                        baseLabel.append(parts.joined(separator: ", "))
                    }
                }

                if let captionText = translatedText ?? self.nonEmptyMessageText(for: message) {
                    baseLabel.append(". ")
                    baseLabel.append(state.strings.VoiceOver_Chat_Caption(captionText).string)
                }

                if isIncoming, announceIncomingAuthors, let authorName {
                    accessibilityLabel = "\(authorName). \(baseLabel)"
                } else if !isIncoming {
                    accessibilityLabel = "\(state.strings.DialogList_You). \(baseLabel)"
                } else {
                    accessibilityLabel = baseLabel
                }

                hint = state.strings.VoiceOver_Chat_OpenHint
                return (typeText, subtitle, accessibilityLabel, hint, traits)
            } else if let _ = media as? TelegramMediaImage {
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
                if let captionText = translatedText ?? self.nonEmptyMessageText(for: message) {
                    accessibilityLabel.append(". ")
                    accessibilityLabel.append(state.strings.VoiceOver_Chat_Caption(captionText).string)
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
                    if let captionText = translatedText ?? self.nonEmptyMessageText(for: message) {
                        accessibilityLabel.append(". ")
                        accessibilityLabel.append(state.strings.VoiceOver_Chat_Caption(captionText).string)
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
        if !textActionItems.isEmpty {
            traits.insert(.button)
            hint = state.strings.VoiceOver_Chat_OpenHint
        }

        return (title, subtitle, accessibilityLabel, hint, traits)
    }

    private func isMessageActivatable(_ message: Message) -> Bool {
        if case .none = self.messageActivation(for: message) {
            return false
        } else {
            return true
        }
    }

    private func activateMessageRow(_ message: Message) -> Bool {
        switch self.messageActivation(for: message) {
        case .none:
            return false
        case .openPoll:
            self.actions.openPollMessage?(message)
            return true
        case .openTodo:
            self.actions.openTodoMessage?(message)
            return true
        case .toggleVoicePlayback:
            self.actions.toggleVoiceMessagePlayback?(message)
            return true
        case .openDefault:
            self.actions.activateMessage?(message)
            return true
        case let .openTextAction(action):
            self.actions.activateMessageTextAction?(message, action)
            return true
        case let .presentTextActions(items):
            self.actions.presentMessageTextActions?(message, items)
            return true
        }
    }

    private func messageActivation(for message: Message) -> MessageActivation {
        if self.pollMedia(in: message) != nil, self.actions.openPollMessage != nil {
            return .openPoll
        }
        if self.todoMedia(in: message) != nil, self.actions.openTodoMessage != nil {
            return .openTodo
        }
        if self.isVoiceMessage(message), self.actions.toggleVoiceMessagePlayback != nil {
            return .toggleVoicePlayback
        }
        if self.usesDefaultMessageActivation(message), self.actions.activateMessage != nil {
            return .openDefault
        }

        let textActionItems = self.messageTextActionItems(for: message)
        if textActionItems.count == 1, self.actions.activateMessageTextAction != nil {
            return .openTextAction(textActionItems[0].action)
        }
        if textActionItems.count > 1, self.actions.presentMessageTextActions != nil {
            return .presentTextActions(textActionItems)
        }

        return .none
    }

    private func usesDefaultMessageActivation(_ message: Message) -> Bool {
        for media in message.media {
            if media is TelegramMediaImage {
                return true
            }
            if let file = media as? TelegramMediaFile, !file.isVoice {
                return true
            }
            if media is TelegramMediaContact {
                return true
            }
            if media is TelegramMediaMap {
                return true
            }
        }
        return false
    }

    private func messageTextActionItems(for message: Message) -> [MessageTextActionItem] {
        if let cached = self.messageTextActionItemsCache[message.id] {
            return cached
        }
        let items = self.buildMessageTextActionItems(for: message)
        self.messageTextActionItemsCache[message.id] = items
        return items
    }

    private func buildMessageTextActionItems(for message: Message) -> [MessageTextActionItem] {
        let translatedContent = self.translatedMessageContent(for: message, state: self.interfaceState)
        let rawText = translatedContent?.text ?? message.text
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        var entities = translatedContent?.entities ?? message.textEntitiesAttribute?.entities ?? []
        if entities.isEmpty {
            entities = generateTextEntities(rawText, enabledTypes: [.all, .timecode])
        }
        guard !entities.isEmpty else {
            return []
        }

        let baseFont = UIFont.preferredFont(forTextStyle: .body)
        let italicDescriptor = baseFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? baseFont.fontDescriptor
        let boldItalicDescriptor = baseFont.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic]) ?? baseFont.fontDescriptor
        let fixedFont = UIFont(name: "Menlo-Regular", size: baseFont.pointSize) ?? baseFont
        let attributedText = stringWithAppliedEntities(
            rawText,
            entities: entities,
            baseColor: .black,
            linkColor: .blue,
            baseFont: baseFont,
            linkFont: baseFont,
            boldFont: UIFont.boldSystemFont(ofSize: baseFont.pointSize),
            italicFont: UIFont(descriptor: italicDescriptor, size: baseFont.pointSize),
            boldItalicFont: UIFont(descriptor: boldItalicDescriptor, size: baseFont.pointSize),
            fixedFont: fixedFont,
            blockQuoteFont: baseFont,
            underlineLinks: false,
            message: message
        )

        let resolvedItems = TelegramTextAttributesVoiceOver.items(in: attributedText)
        guard !resolvedItems.isEmpty else {
            return []
        }

        var uniqueItems: [(item: MessageTextActionItem, range: NSRange)] = []
        for item in resolvedItems {
            let title = self.messageTextActionTitle(for: item)
            guard !title.isEmpty else {
                continue
            }
            if uniqueItems.contains(where: { $0.range == item.range && $0.item.action == item.action }) {
                continue
            }
            uniqueItems.append((MessageTextActionItem(action: item.action, title: title), item.range))
        }

        var duplicateCounts: [String: Int] = [:]
        for item in uniqueItems {
            duplicateCounts[item.item.title, default: 0] += 1
        }
        var seenDuplicateIndices: [String: Int] = [:]

        return uniqueItems.map { entry in
            guard duplicateCounts[entry.item.title, default: 0] > 1 else {
                return entry.item
            }
            let nextIndex = seenDuplicateIndices[entry.item.title, default: 0] + 1
            seenDuplicateIndices[entry.item.title] = nextIndex
            return MessageTextActionItem(action: entry.item.action, title: "\(entry.item.title) (\(nextIndex))")
        }
    }

    private func messageTextActionTitle(for item: TelegramTextAttributesVoiceOver.Item) -> String {
        let trimmedText = item.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            return trimmedText
        }
        switch item.action {
        case let .url(url, _):
            return url
        case let .peerMention(_, mention):
            return mention
        case let .textMention(name):
            return name
        case let .botCommand(command):
            return command
        case let .hashtag(_, hashtag):
            return hashtag
        case let .timecode(_, text):
            return text
        }
    }

    private func textSelectionContent(for message: Message) -> NSAttributedString? {
        if let translatedText = self.translatedMessageText(for: message, state: self.interfaceState) {
            return NSAttributedString(string: translatedText)
        }

        if let transcribedText = transcribedText(message: message) {
            switch transcribedText {
            case let .success(text, _):
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedText.isEmpty {
                    return NSAttributedString(string: text)
                }
            case .error:
                break
            }
        }

        let trimmedMessageText = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedMessageText.isEmpty {
            return NSAttributedString(string: message.text)
        }

        return nil
    }

    private func transcriptText(for message: Message) -> String? {
        if let translatedText = self.translatedMessageText(for: message, state: self.interfaceState), self.isVoiceMessage(message) {
            return translatedText
        }
        guard let transcribedText = transcribedText(message: message) else {
            return nil
        }
        switch transcribedText {
        case let .success(text, _):
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedText.isEmpty ? nil : text
        case .error:
            return nil
        }
    }

    private func transcriptAccessibilityValue(for message: Message) -> String? {
        guard self.isVoiceMessage(message), let transcriptText = self.transcriptText(for: message) else {
            return nil
        }
        return transcriptText
    }

    private func normalizedTranslationLanguage(_ language: String?) -> String? {
        guard let language, !language.isEmpty else {
            return nil
        }
        let rawSuffix = "-raw"
        if language.hasSuffix(rawSuffix) {
            return String(language.dropLast(rawSuffix.count))
        }
        return language
    }

    private func activeTranslationLanguage(for state: ChatPresentationInterfaceState?) -> String? {
        guard let translationState = state?.translationState, translationState.isEnabled else {
            return nil
        }
        return self.normalizedTranslationLanguage(translationState.toLang)
    }

    private func translationAttribute(for message: Message, state: ChatPresentationInterfaceState?) -> TranslationMessageAttribute? {
        guard let targetLanguage = self.activeTranslationLanguage(for: state) else {
            return nil
        }
        return message.attributes.first(where: { attribute in
            guard let attribute = attribute as? TranslationMessageAttribute else {
                return false
            }
            return self.normalizedTranslationLanguage(attribute.toLang) == targetLanguage
        }) as? TranslationMessageAttribute
    }

    private func translatedMessageContent(for message: Message, state: ChatPresentationInterfaceState?) -> (text: String, entities: [MessageTextEntity])? {
        guard let translation = self.translationAttribute(for: message, state: state) else {
            return nil
        }
        let trimmedText = translation.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }
        return (translation.text, translation.entities)
    }

    private func translatedMessageText(for message: Message, state: ChatPresentationInterfaceState?) -> String? {
        return self.translatedMessageContent(for: message, state: state)?.text
    }

    private func nonEmptyMessageText(for message: Message) -> String? {
        let trimmedText = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return nil
        }
        return message.text
    }

    private func supportsAudioTranscription(for message: Message) -> Bool {
        for media in message.media {
            if let file = media as? TelegramMediaFile, file.isVoice || file.isInstantVideo {
                return true
            }
        }
        return false
    }

    private func makeMessageAccessibilityCustomActions(message: Message, state: ChatPresentationInterfaceState, menuRectProvider: @escaping () -> CGRect?) -> [UIAccessibilityCustomAction] {
        var customActions: [UIAccessibilityCustomAction] = []

        let textActionItems = self.messageTextActionItems(for: message)
        for item in textActionItems {
            customActions.append(UIAccessibilityCustomAction(name: item.title, actionHandler: { [weak self] _ in
                guard let self else {
                    return false
                }
                self.noteVoiceOverNavigationActivity()
                self.actions.activateMessageTextAction?(message, item.action)
                return true
            }))
        }

        if let selectionContent = self.textSelectionContent(for: message), let performTextSelectionAction = self.actions.performTextSelectionAction {
            let translateTitle = state.strings.Conversation_ContextMenuTranslate
            customActions.append(UIAccessibilityCustomAction(name: translateTitle, actionHandler: { [weak self] _ in
                guard let self else {
                    return false
                }
                self.noteVoiceOverNavigationActivity()
                performTextSelectionAction(message, selectionContent, .translate)
                return true
            }))
        }

        if let transcriptText = self.transcriptText(for: message), let viewAudioTranscript = self.actions.viewAudioTranscript {
            let transcriptTitle = "View Transcript"
            customActions.append(UIAccessibilityCustomAction(name: transcriptTitle, actionHandler: { [weak self] _ in
                guard let self else {
                    return false
                }
                self.noteVoiceOverNavigationActivity()
                if !transcriptText.isEmpty {
                    viewAudioTranscript(message)
                }
                return true
            }))
        } else if self.supportsAudioTranscription(for: message), let requestAudioTranscription = self.actions.requestAudioTranscription {
            let transcriptionTitle = state.strings.GroupBoost_AudioTranscription
            customActions.append(UIAccessibilityCustomAction(name: transcriptionTitle, actionHandler: { [weak self] _ in
                guard let self else {
                    return false
                }
                self.noteVoiceOverNavigationActivity()
                requestAudioTranscription(message)
                return true
            }))
        }

        let moreTitle = state.strings.Conversation_ContextMenuMore
        customActions.append(UIAccessibilityCustomAction(name: moreTitle, actionHandler: { [weak self] _ in
            guard let self, let rect = menuRectProvider() else {
                return false
            }
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

        return customActions
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
            if let target = self.accessibilityFocusTarget(at: indexPath) {
                UIAccessibility.post(notification: .screenChanged, argument: target)
            } else {
                UIAccessibility.post(notification: .screenChanged, argument: self.tableView)
            }
        }
    }

    private func setupKeyboardObservers() {
        let nc = NotificationCenter.default
        let frameToken = nc.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] notification in
            self?.handleKeyboard(notification: notification)
        }
        let willHideToken = nc.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scheduleKeyboardDismissFocusRestoreIfNeeded(after: 0.12)
        }
        let didHideToken = nc.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.scheduleKeyboardDismissFocusRestoreIfNeeded(after: 0.05)
        }
        self.keyboardObservers.append(frameToken)
        self.keyboardObservers.append(willHideToken)
        self.keyboardObservers.append(didHideToken)
    }

    private func setupAccessibilityObservers() {
        let nc = NotificationCenter.default
        let token = nc.addObserver(forName: UIAccessibility.elementFocusedNotification, object: nil, queue: .main) { [weak self] notification in
            self?.handleAccessibilityElementFocused(notification: notification)
        }
        self.accessibilityObservers.append(token)

        let textDidChangeToken = nc.addObserver(forName: UITextView.textDidChangeNotification, object: self.inputTextView, queue: .main) { [weak self] _ in
            self?.updateComposerPrimaryActionButtons()
        }
        self.accessibilityObservers.append(textDidChangeToken)
    }

    private func handleAccessibilityElementFocused(notification: Notification) {
        guard UIAccessibility.isVoiceOverRunning, let userInfo = notification.userInfo else {
            return
        }

        let focusedElement = userInfo[UIAccessibility.focusedElementUserInfoKey]

        if self.usesNativeVoiceOverAccessibility {
            if self.accessibilityViewIsModal, !self.accessibilityElementsHidden, !self.isVoiceOverElementWithinOverlay(focusedElement) {
                self.scheduleVoiceOverFocusRecoveryIfNeeded()
            }
            return
        }
        let isCustomScrollbarFocused: Bool = {
            guard let focusedScrollbar = focusedElement as? ChatVoiceOverOverlayScrollbarAccessibilityElement else {
                return false
            }
            return focusedScrollbar.overlay === self
        }()

        if isCustomScrollbarFocused {
            if self.voiceOverScrollbarAccessibilityElementAnchorTableRow == nil {
                let baseRowCount = max(0, self.tableView.numberOfRows(inSection: 0))
                let hasLoadEarlierRow: Bool = {
                    guard let first = self.tableAccessibilityElement(at: 0) as? ChatVoiceOverOverlayRowAccessibilityElement else {
                        return false
                    }
                    if case .loadEarlier = first.kind {
                        return true
                    } else {
                        return false
                    }
                }()
                let firstMessageRow = hasLoadEarlierRow ? 1 : 0

                let resolvedAnchorRow: Int = {
                    guard baseRowCount > 0 else {
                        return firstMessageRow
                    }
                    let lastRow = max(0, baseRowCount - 1)
                    let hasMessageRows = baseRowCount > firstMessageRow

                    if self.voiceOverScrollbarIsAtBottom(visibleIndexPaths: self.voiceOverScrollbarVisibleIndexPathsSorted()) {
                        return lastRow
                    }
                    if self.voiceOverScrollbarIsAtTop(visibleIndexPaths: self.voiceOverScrollbarVisibleIndexPathsSorted()) {
                        return hasMessageRows ? firstMessageRow : lastRow
                    }

                    if let unfocusedRowElement = userInfo[UIAccessibility.unfocusedElementUserInfoKey] as? ChatVoiceOverOverlayRowAccessibilityElement,
                       unfocusedRowElement.overlay === self,
                       let unfocusedIndexPath = self.indexPath(for: unfocusedRowElement),
                       unfocusedIndexPath.section == 0
                    {
                        return max(firstMessageRow, min(baseRowCount - 1, unfocusedIndexPath.row))
                    }
                    if let visibleIndexPaths = self.tableView.indexPathsForVisibleRows?.sorted(), !visibleIndexPaths.isEmpty {
                        let candidates = visibleIndexPaths.filter { $0.section == 0 && $0.row >= firstMessageRow }
                        let effectiveCandidates = candidates.isEmpty ? visibleIndexPaths : candidates
                        let visibleMidY = self.tableView.contentOffset.y + self.tableView.bounds.height * 0.5
                        var best = effectiveCandidates[0]
                        var bestDistance = abs(self.tableView.rectForRow(at: best).midY - visibleMidY)
                        for indexPath in effectiveCandidates.dropFirst() {
                            let distance = abs(self.tableView.rectForRow(at: indexPath).midY - visibleMidY)
                            if distance < bestDistance {
                                bestDistance = distance
                                best = indexPath
                            }
                        }
                        return max(firstMessageRow, min(baseRowCount - 1, best.row))
                    } else {
                        return max(firstMessageRow, min(baseRowCount - 1, baseRowCount / 2))
                    }
                }()
                self.setVoiceOverScrollbarAccessibilityElementActive(true, anchorTableRow: resolvedAnchorRow)
            }
        } else {
            self.setVoiceOverScrollbarAccessibilityElementActive(false, anchorTableRow: nil)
            if self.accessibilityViewIsModal, !self.accessibilityElementsHidden, !self.isVoiceOverElementWithinOverlay(focusedElement) {
                self.scheduleVoiceOverFocusRecoveryIfNeeded()
            }
        }
    }

    private func updateComposerAccessibilityVisibility() {
        let isScrollbarActive = !self.usesNativeVoiceOverAccessibility && (self.voiceOverScrollbarAccessibilityElementAnchorTableRow != nil)
        self.composerView.accessibilityElementsHidden = isScrollbarActive
        self.voicePlayerView.accessibilityElementsHidden = isScrollbarActive
        if self.isComposerEnabled {
            var elements: [Any] = [
                self.attachButton,
                self.inputTextView as Any
            ]
            if !self.sendButton.isHidden {
                elements.append(self.sendButton)
            }
            if !self.recordButton.isHidden {
                elements.append(self.recordButton)
            }
            self.composerView.accessibilityElements = elements
        } else {
            self.composerView.accessibilityElements = []
        }
    }

    private func requestVisibleTranslationsIfNeeded() {
        guard UIAccessibility.isVoiceOverRunning else {
            return
        }
        guard self.activeTranslationLanguage(for: self.interfaceState) != nil else {
            return
        }
        guard let visibleIndexPaths = self.tableView.indexPathsForVisibleRows, !visibleIndexPaths.isEmpty else {
            return
        }

        let rowOffset = self.loadEarlierRowOffset
        var messageIds: [MessageId] = []
        messageIds.reserveCapacity(visibleIndexPaths.count)

        for indexPath in visibleIndexPaths.sorted() {
            guard indexPath.section == 0 else {
                continue
            }
            let rowIndex = indexPath.row - rowOffset
            guard rowIndex >= 0, rowIndex < self.rows.count else {
                continue
            }
            guard case let .message(message) = self.rows[rowIndex].kind else {
                continue
            }
            messageIds.append(message.id)
        }

        guard !messageIds.isEmpty else {
            return
        }
        self.actions.requestVisibleTranslations?(messageIds)
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
        let previousOverlap = self.lastKnownKeyboardOverlap
        self.lastKnownKeyboardOverlap = overlap

        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? UIView.AnimationCurve.easeInOut.rawValue
        let curve = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))

        self.composerBottomConstraint?.constant = -overlap

        UIView.animate(withDuration: duration, delay: 0.0, options: [curve, .beginFromCurrentState]) {
            self.layoutIfNeeded()
        }

        if overlap > 0.0 {
            self.keyboardDismissFocusRestoreWorkItem?.cancel()
            self.keyboardDismissFocusRestoreWorkItem = nil
        } else if previousOverlap > 0.0 {
            self.scheduleKeyboardDismissFocusRestoreIfNeeded(after: max(0.1, duration + 0.05))
        }
    }
}

extension ChatVoiceOverOverlayView: UITableViewDataSource, UITableViewDelegate, ChatInputTextNodeDelegate {
}
