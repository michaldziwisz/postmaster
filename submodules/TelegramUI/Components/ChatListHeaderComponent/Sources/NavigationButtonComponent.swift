import Foundation
import UIKit
import ComponentFlow
import ChatListTitleView
import TelegramPresentationData
import Display
import MoreHeaderButton

public final class NavigationButtonComponentEnvironment: Equatable {
    public let theme: PresentationTheme
    public let strings: PresentationStrings
    
    public init(theme: PresentationTheme, strings: PresentationStrings) {
        self.theme = theme
        self.strings = strings
    }
    
    public static func ==(lhs: NavigationButtonComponentEnvironment, rhs: NavigationButtonComponentEnvironment) -> Bool {
        if lhs.theme != rhs.theme {
            return false
        }
        if lhs.strings !== rhs.strings {
            return false
        }
        return true
    }
}

public final class NavigationButtonComponent: Component {
    public typealias EnvironmentType = NavigationButtonComponentEnvironment
    
    public enum Content: Equatable {
        case text(title: String, isBold: Bool)
        case more
        case icon(imageName: String)
        case proxy(status: ChatTitleProxyStatus)
    }
    
    public let content: Content
    public let accessibilityLabel: String?
    public let accessibilityHint: String?
    public let pressed: (UIView) -> Void
    public let contextAction: ((UIView, ContextGesture?) -> Void)?
    
    public init(
        content: Content,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        pressed: @escaping (UIView) -> Void,
        contextAction: ((UIView, ContextGesture?) -> Void)? = nil
    ) {
        self.content = content
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.pressed = pressed
        self.contextAction = contextAction
    }
    
    public static func ==(lhs: NavigationButtonComponent, rhs: NavigationButtonComponent) -> Bool {
        if lhs.content != rhs.content {
            return false
        }
        if lhs.accessibilityLabel != rhs.accessibilityLabel {
            return false
        }
        if lhs.accessibilityHint != rhs.accessibilityHint {
            return false
        }
        return true
    }
    
    public final class View: HighlightTrackingButton {
        private var textView: ImmediateTextView?
        
        private var iconView: UIImageView?
        private var iconImageName: String?
        
        private var proxyNode: ChatTitleProxyNode?
        
        private var moreButton: MoreHeaderButton?
        
        private var component: NavigationButtonComponent?
        private var theme: PresentationTheme?
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            self.addTarget(self, action: #selector(self.pressed), for: .touchUpInside)
            
            self.highligthedChanged = { [weak self] highlighted in
                guard let self else {
                    return
                }
                if highlighted {
                    self.textView?.alpha = 0.6
                    self.proxyNode?.alpha = 0.6
                    self.iconView?.alpha = 0.6
                } else {
                    self.textView?.alpha = 1.0
                    self.textView?.layer.animateAlpha(from: 0.6, to: 1.0, duration: 0.2)
                    
                    self.proxyNode?.alpha = 1.0
                    self.proxyNode?.layer.animateAlpha(from: 0.6, to: 1.0, duration: 0.2)
                    
                    self.iconView?.alpha = 1.0
                    self.iconView?.layer.animateAlpha(from: 0.6, to: 1.0, duration: 0.2)
                }
            }
        }
        
        required public init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private static func defaultAccessibilityLabel(forIconImageName imageName: String) -> String? {
            let baseName = imageName.split(separator: "/").last.map(String.init) ?? imageName
            let withoutExtension = baseName.split(separator: ".").first.map(String.init) ?? baseName
            
            var label = withoutExtension
            for suffix in ["Icon", "Button"] {
                if label.hasSuffix(suffix) {
                    label.removeLast(suffix.count)
                    break
                }
            }
            
            label = label.replacingOccurrences(of: "_", with: " ")
            label = label.replacingOccurrences(of: "-", with: " ")
            label = label.replacingOccurrences(of: "([A-Z]+)([A-Z][a-z])", with: "$1 $2", options: .regularExpression)
            label = label.replacingOccurrences(of: "([a-z0-9])([A-Z])", with: "$1 $2", options: .regularExpression)
            label = label.trimmingCharacters(in: .whitespacesAndNewlines)
            
            return label.isEmpty ? nil : label
        }
        
        override public func accessibilityActivate() -> Bool {
            self.sendActions(for: .touchUpInside)
            return true
        }
        
        @objc private func pressed() {
            self.component?.pressed(self)
        }
        
        func update(component: NavigationButtonComponent, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
            self.component = component
            
            let theme = environment[NavigationButtonComponentEnvironment.self].value.theme
            let strings = environment[NavigationButtonComponentEnvironment.self].value.strings
            var themeUpdated = false
            if self.theme !== theme {
                self.theme = theme
                themeUpdated = true
            }
            
            var textString: NSAttributedString?
            var imageName: String?
            var proxyStatus: ChatTitleProxyStatus?
            var isMore: Bool = false
            
            switch component.content {
            case let .text(title, isBold):
                textString = NSAttributedString(string: title, font: isBold ? Font.bold(17.0) : Font.medium(17.0), textColor: theme.chat.inputPanel.panelControlColor)
            case .more:
                isMore = true
            case let .icon(imageNameValue):
                imageName = imageNameValue
            case let .proxy(status):
                proxyStatus = status
            }

            self.isAccessibilityElement = true
            var accessibilityTraits: UIAccessibilityTraits = [.button]
            if !self.isEnabled {
                accessibilityTraits.insert(.notEnabled)
            }
            self.accessibilityTraits = accessibilityTraits
            self.accessibilityHint = component.accessibilityHint
            if let accessibilityLabel = component.accessibilityLabel {
                self.accessibilityLabel = accessibilityLabel
            } else {
                switch component.content {
                case let .text(title, _):
                    self.accessibilityLabel = title
                case .more:
                    self.accessibilityLabel = strings.Common_More
                case let .icon(imageName):
                    self.accessibilityLabel = Self.defaultAccessibilityLabel(forIconImageName: imageName)
                case .proxy:
                    self.accessibilityLabel = strings.VoiceOver_Navigation_ProxySettings
                }
            }
            
            var size = CGSize(width: 0.0, height: availableSize.height)
            
            if let textString = textString {
                let textView: ImmediateTextView
                if let current = self.textView {
                    textView = current
                } else {
                    textView = ImmediateTextView()
                    textView.isUserInteractionEnabled = false
                    self.textView = textView
                    self.addSubview(textView)
                }
                
                textView.attributedText = textString
                let textSize = textView.updateLayout(availableSize)
                let textInset: CGFloat = 12.0
                size.width = max(44.0, textSize.width + textInset * 2.0)
                
                textView.frame = CGRect(origin: CGPoint(x: floor((size.width - textSize.width) / 2.0), y: floor((availableSize.height - textSize.height) / 2.0)), size: textSize)
            } else if let textView = self.textView {
                self.textView = nil
                textView.removeFromSuperview()
            }
            
            if let imageName = imageName {
                let iconView: UIImageView
                if let current = self.iconView {
                    iconView = current
                } else {
                    iconView = UIImageView()
                    iconView.isUserInteractionEnabled = false
                    self.iconView = iconView
                    self.addSubview(iconView)
                }
                if self.iconImageName != imageName || themeUpdated {
                    self.iconImageName = imageName
                    iconView.image = generateTintedImage(image: UIImage(bundleImageName: imageName), color: theme.chat.inputPanel.panelControlColor)
                }
                
                if let iconSize = iconView.image?.size {
                    size.width = 44.0
                    
                    iconView.frame = CGRect(origin: CGPoint(x: floor((size.width - iconSize.width) / 2.0), y: floor((availableSize.height - iconSize.height) / 2.0)), size: iconSize)
                }
            } else if let iconView = self.iconView {
                self.iconView = nil
                iconView.removeFromSuperview()
                self.iconImageName = nil
            }
            
            if let proxyStatus = proxyStatus {
                let proxyNode: ChatTitleProxyNode
                if let current = self.proxyNode {
                    proxyNode = current
                } else {
                    proxyNode = ChatTitleProxyNode(theme: theme)
                    proxyNode.isUserInteractionEnabled = false
                    self.proxyNode = proxyNode
                    self.addSubnode(proxyNode)
                }
                
                let proxySize = CGSize(width: 30.0, height: 30.0)
                size.width = 44.0
                
                proxyNode.theme = theme
                proxyNode.status = proxyStatus
                
                proxyNode.frame = CGRect(origin: CGPoint(x: floor((size.width - proxySize.width) / 2.0), y: floor((availableSize.height - proxySize.height) / 2.0)), size: proxySize)
            } else if let proxyNode = self.proxyNode {
                self.proxyNode = nil
                proxyNode.removeFromSupernode()
            }
            
            if isMore {
                let moreButton: MoreHeaderButton
                if let current = self.moreButton, !themeUpdated {
                    moreButton = current
                } else {
                    if let moreButton = self.moreButton {
                        moreButton.removeFromSupernode()
                        self.moreButton = nil
                    }
                    
                    moreButton = MoreHeaderButton(color: theme.chat.inputPanel.panelControlColor, accessibilityLabel: strings.Common_More)
                    moreButton.isUserInteractionEnabled = true
                    moreButton.setContent(.more(MoreHeaderButton.optionsCircleImage(color: theme.chat.inputPanel.panelControlColor)))
                    moreButton.onPressed = { [weak self] in
                        guard let self, let component = self.component else {
                            return
                        }
                        self.moreButton?.play()
                        component.pressed(self)
                    }
                    moreButton.contextAction = { [weak self] sourceNode, gesture in
                        guard let self, let component = self.component else {
                            return
                        }
                        self.moreButton?.play()
                        component.contextAction?(self, gesture)
                    }
                    self.moreButton = moreButton
                    self.addSubnode(moreButton)
                }
                
                moreButton.accessibilityLabel = strings.Common_More
                let buttonSize = CGSize(width: 44.0, height: 44.0)
                size.width = 44.0
                
                moreButton.setContent(.more(MoreHeaderButton.optionsCircleImage(color: theme.rootController.navigationBar.buttonColor)))
                
                moreButton.frame = CGRect(origin: CGPoint(x: floor((size.width - buttonSize.width) / 2.0), y: floor((size.height - buttonSize.height) / 2.0)), size: buttonSize)
            } else if let moreButton = self.moreButton {
                self.moreButton = nil
                moreButton.removeFromSupernode()
            }
            
            return size
        }
    }
    
    public func makeView() -> View {
        return View(frame: CGRect())
    }
    
    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<NavigationButtonComponentEnvironment>, transition: ComponentTransition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, state: state, environment: environment, transition: transition)
    }
}
