import Foundation
import UIKit

public final class Button: Component {
    public let content: AnyComponent<Empty>
    public let contentInsets: UIEdgeInsets
    public let minSize: CGSize?
    public let hitTestEdgeInsets: UIEdgeInsets?
    public let tag: AnyObject?
    public let automaticHighlight: Bool
    public let isEnabled: Bool
    public let isExclusive: Bool
    public let action: () -> Void
    public let holdAction: ((UIView) -> Void)?
    public let highlightedAction: ActionSlot<Bool>?
    public let accessibilityLabel: String?
    public let accessibilityValue: String?
    public let accessibilityHint: String?
    public let accessibilityTraits: UIAccessibilityTraits
    public let isVisible: Bool

    convenience public init(
        content: AnyComponent<Empty>,
        contentInsets: UIEdgeInsets = UIEdgeInsets(),
        isEnabled: Bool = true,
        automaticHighlight: Bool = true,
        action: @escaping () -> Void,
        highlightedAction: ActionSlot<Bool>? = nil,
        accessibilityLabel: String? = nil,
        accessibilityValue: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityTraits: UIAccessibilityTraits = [],
        isVisible: Bool = true
    ) {
        self.init(
            content: content,
            contentInsets: contentInsets,
            minSize: nil,
            hitTestEdgeInsets: nil,
            tag: nil,
            automaticHighlight: automaticHighlight,
            isEnabled: isEnabled,
            action: action,
            holdAction: nil,
            highlightedAction: highlightedAction,
            accessibilityLabel: accessibilityLabel,
            accessibilityValue: accessibilityValue,
            accessibilityHint: accessibilityHint,
            accessibilityTraits: accessibilityTraits,
            isVisible: isVisible
        )
    }
    
    private init(
        content: AnyComponent<Empty>,
        contentInsets: UIEdgeInsets = UIEdgeInsets(),
        minSize: CGSize? = nil,
        hitTestEdgeInsets: UIEdgeInsets? = nil,
        tag: AnyObject? = nil,
        automaticHighlight: Bool = true,
        isEnabled: Bool = true,
        isExclusive: Bool = true,
        action: @escaping () -> Void,
        holdAction: ((UIView) -> Void)?,
        highlightedAction: ActionSlot<Bool>?,
        accessibilityLabel: String? = nil,
        accessibilityValue: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityTraits: UIAccessibilityTraits = [],
        isVisible: Bool = true
    ) {
        self.content = content
        self.contentInsets = contentInsets
        self.minSize = minSize
        self.hitTestEdgeInsets = hitTestEdgeInsets
        self.tag = tag
        self.automaticHighlight = automaticHighlight
        self.isEnabled = isEnabled
        self.isExclusive = isExclusive
        self.action = action
        self.holdAction = holdAction
        self.highlightedAction = highlightedAction
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
        self.accessibilityHint = accessibilityHint
        self.accessibilityTraits = accessibilityTraits
        self.isVisible = isVisible
    }
    
    public func minSize(_ minSize: CGSize?) -> Button {
        return Button(
            content: self.content,
            contentInsets: self.contentInsets,
            minSize: minSize,
            hitTestEdgeInsets: self.hitTestEdgeInsets,
            tag: self.tag,
            automaticHighlight: self.automaticHighlight,
            isEnabled: self.isEnabled,
            isExclusive: self.isExclusive,
            action: self.action,
            holdAction: self.holdAction,
            highlightedAction: self.highlightedAction,
            accessibilityLabel: self.accessibilityLabel,
            accessibilityValue: self.accessibilityValue,
            accessibilityHint: self.accessibilityHint,
            accessibilityTraits: self.accessibilityTraits,
            isVisible: self.isVisible
        )
    }
    
    public func withHitTestEdgeInsets(_ hitTestEdgeInsets: UIEdgeInsets?) -> Button {
        return Button(
            content: self.content,
            contentInsets: self.contentInsets,
            minSize: self.minSize,
            hitTestEdgeInsets: hitTestEdgeInsets,
            tag: self.tag,
            automaticHighlight: self.automaticHighlight,
            isEnabled: self.isEnabled,
            isExclusive: self.isExclusive,
            action: self.action,
            holdAction: self.holdAction,
            highlightedAction: self.highlightedAction,
            accessibilityLabel: self.accessibilityLabel,
            accessibilityValue: self.accessibilityValue,
            accessibilityHint: self.accessibilityHint,
            accessibilityTraits: self.accessibilityTraits,
            isVisible: self.isVisible
        )
    }
    
    public func withIsExclusive(_ isExclusive: Bool) -> Button {
        return Button(
            content: self.content,
            contentInsets: self.contentInsets,
            minSize: self.minSize,
            hitTestEdgeInsets: self.hitTestEdgeInsets,
            tag: self.tag,
            automaticHighlight: self.automaticHighlight,
            isEnabled: self.isEnabled,
            isExclusive: isExclusive,
            action: self.action,
            holdAction: self.holdAction,
            highlightedAction: self.highlightedAction,
            accessibilityLabel: self.accessibilityLabel,
            accessibilityValue: self.accessibilityValue,
            accessibilityHint: self.accessibilityHint,
            accessibilityTraits: self.accessibilityTraits,
            isVisible: self.isVisible
        )
    }
    
    
    public func withHoldAction(_ holdAction: ((UIView) -> Void)?) -> Button {
        return Button(
            content: self.content,
            contentInsets: self.contentInsets,
            minSize: self.minSize,
            hitTestEdgeInsets: self.hitTestEdgeInsets,
            tag: self.tag,
            automaticHighlight: self.automaticHighlight,
            isEnabled: self.isEnabled,
            isExclusive: self.isExclusive,
            action: self.action,
            holdAction: holdAction,
            highlightedAction: self.highlightedAction,
            accessibilityLabel: self.accessibilityLabel,
            accessibilityValue: self.accessibilityValue,
            accessibilityHint: self.accessibilityHint,
            accessibilityTraits: self.accessibilityTraits,
            isVisible: self.isVisible
        )
    }
    
    public func withAccessibility(
        label: String?,
        value: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits = [],
        isVisible: Bool = true
    ) -> Button {
        return Button(
            content: self.content,
            contentInsets: self.contentInsets,
            minSize: self.minSize,
            hitTestEdgeInsets: self.hitTestEdgeInsets,
            tag: self.tag,
            automaticHighlight: self.automaticHighlight,
            isEnabled: self.isEnabled,
            isExclusive: self.isExclusive,
            action: self.action,
            holdAction: self.holdAction,
            highlightedAction: self.highlightedAction,
            accessibilityLabel: label,
            accessibilityValue: value,
            accessibilityHint: hint,
            accessibilityTraits: traits,
            isVisible: isVisible
        )
    }
    
    public func tagged(_ tag: AnyObject) -> Button {
        return Button(
            content: self.content,
            contentInsets: self.contentInsets,
            minSize: self.minSize,
            hitTestEdgeInsets: self.hitTestEdgeInsets,
            tag: tag,
            automaticHighlight: self.automaticHighlight,
            isEnabled: self.isEnabled,
            isExclusive: self.isExclusive,
            action: self.action,
            holdAction: self.holdAction,
            highlightedAction: self.highlightedAction,
            accessibilityLabel: self.accessibilityLabel,
            accessibilityValue: self.accessibilityValue,
            accessibilityHint: self.accessibilityHint,
            accessibilityTraits: self.accessibilityTraits,
            isVisible: self.isVisible
        )
    }
    
    public static func ==(lhs: Button, rhs: Button) -> Bool {
        if lhs.content != rhs.content {
            return false
        }
        if lhs.contentInsets != rhs.contentInsets {
            return false
        }
        if lhs.minSize != rhs.minSize {
            return false
        }
        if lhs.hitTestEdgeInsets != rhs.hitTestEdgeInsets {
            return false
        }
        if lhs.tag !== rhs.tag {
            return false
        }
        if lhs.automaticHighlight != rhs.automaticHighlight {
            return false
        }
        if lhs.isEnabled != rhs.isEnabled {
            return false
        }
        if lhs.isExclusive != rhs.isExclusive {
            return false
        }
        if lhs.accessibilityLabel != rhs.accessibilityLabel {
            return false
        }
        if lhs.accessibilityValue != rhs.accessibilityValue {
            return false
        }
        if lhs.accessibilityHint != rhs.accessibilityHint {
            return false
        }
        if lhs.accessibilityTraits != rhs.accessibilityTraits {
            return false
        }
        if lhs.isVisible != rhs.isVisible {
            return false
        }
        return true
    }
    
    public final class View: UIButton, ComponentTaggedView {
        private let contentView: ComponentHostView<Empty>
        
        public var content: UIView? {
            return self.contentView.componentView
        }
        
        private var component: Button?
        private var currentIsHighlighted: Bool = false {
            didSet {
                guard let component = self.component else {
                    return
                }
                if self.currentIsHighlighted != oldValue {
                    if component.automaticHighlight {
                        self.updateAlpha(transition: .immediate)
                    }
                    component.highlightedAction?.invoke(self.currentIsHighlighted)
                }
            }
        }
        
        private func updateAlpha(transition: ComponentTransition) {
            guard let component = self.component else {
                return
            }
            let alpha: CGFloat
            if component.isEnabled {
                if component.automaticHighlight {
                    alpha = self.currentIsHighlighted ? 0.6 : 1.0
                } else {
                    alpha = 1.0
                }
            } else {
                alpha = 0.3
            }
            transition.setAlpha(view: self.contentView, alpha: alpha)
        }
        
        private var holdActionTriggerred: Bool = false
        private var holdActionTimer: Timer?
        
        public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            var bounds = self.bounds
            if let hitTestEdgeInsets = self.component?.hitTestEdgeInsets {
                bounds = bounds.insetBy(dx: hitTestEdgeInsets.left, dy: hitTestEdgeInsets.top)
            }
            return bounds.contains(point)
        }
        
        override init(frame: CGRect) {
            self.contentView = ComponentHostView<Empty>()
            self.contentView.isUserInteractionEnabled = false
            self.contentView.layer.allowsGroupOpacity = true
            
            super.init(frame: frame)
            
            self.addSubview(self.contentView)
            
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            self.holdActionTimer?.invalidate()
        }
        
        public func matches(tag: Any) -> Bool {
            if let component = self.component, let componentTag = component.tag {
                let tag = tag as AnyObject
                if componentTag === tag {
                    return true
                }
            }
            return false
        }
        
        @objc private func pressed() {
            if self.holdActionTriggerred {
                self.holdActionTriggerred = false
            } else {
                self.component?.action()
            }
        }
        
        override public func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            self.currentIsHighlighted = true
            
            self.holdActionTriggerred = false
            
            if self.component?.holdAction != nil {
                self.holdActionTriggerred = true
                self.component?.action()
                
                self.holdActionTimer?.invalidate()
                if #available(iOS 10.0, *) {
                    let holdActionTimer = Timer(timeInterval: 0.5, repeats: false, block: { [weak self] _ in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.holdActionTimer?.invalidate()
                        strongSelf.component?.holdAction?(strongSelf)
                        strongSelf.beginExecuteHoldActionTimer()
                    })
                    self.holdActionTimer = holdActionTimer
                    RunLoop.main.add(holdActionTimer, forMode: .common)
                }
            }
            
            return super.beginTracking(touch, with: event)
        }
        
        private func beginExecuteHoldActionTimer() {
            self.holdActionTimer?.invalidate()
            if #available(iOS 10.0, *) {
                let holdActionTimer = Timer(timeInterval: 0.1, repeats: true, block: { [weak self] _ in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.component?.holdAction?(strongSelf)
                })
                self.holdActionTimer = holdActionTimer
                RunLoop.main.add(holdActionTimer, forMode: .common)
            }
        }
        
        override public func endTracking(_ touch: UITouch?, with event: UIEvent?) {
            self.currentIsHighlighted = false
            
            self.holdActionTimer?.invalidate()
            self.holdActionTimer = nil
            
            super.endTracking(touch, with: event)
        }
        
        override public func cancelTracking(with event: UIEvent?) {
            self.currentIsHighlighted = false
            
            self.holdActionTimer?.invalidate()
            self.holdActionTimer = nil
            
            super.cancelTracking(with: event)
        }
	        
	        func update(component: Button, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
	            let contentSize = self.contentView.update(
	                transition: transition,
                component: component.content,
                environment: {},
                containerSize: availableSize
            )
            
            var size = contentSize
            if let minSize = component.minSize {
                size.width = max(size.width, minSize.width)
                size.height = max(size.height, minSize.height)
            }
            size.width += component.contentInsets.left + component.contentInsets.right
            size.height += component.contentInsets.top + component.contentInsets.bottom
            
            self.component = component
	            
	            self.updateAlpha(transition: transition)
	            self.isEnabled = component.isEnabled
	            self.isExclusiveTouch = component.isExclusive
	            
	            self.isAccessibilityElement = component.isVisible
	            self.accessibilityElementsHidden = !component.isVisible
	            self.accessibilityLabel = component.accessibilityLabel
	            self.accessibilityValue = component.accessibilityValue
	            self.accessibilityHint = component.accessibilityHint
	            
	            var traits: UIAccessibilityTraits = [.button]
	            traits.formUnion(component.accessibilityTraits)
	            if !component.isEnabled {
	                traits.insert(.notEnabled)
	            }
	            self.accessibilityTraits = traits
	            
	            transition.setFrame(view: self.contentView, frame: CGRect(origin: CGPoint(x: floor((size.width - contentSize.width) / 2.0), y: floor((size.height - contentSize.height) / 2.0)), size: contentSize), completion: nil)
	            
	            return size
	        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: ComponentTransition) -> CGSize {
        view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
