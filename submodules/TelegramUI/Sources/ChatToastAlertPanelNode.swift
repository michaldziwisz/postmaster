import Foundation
import UIKit
import Display
import AsyncDisplayKit
import ChatPresentationInterfaceState
import LegacyChatHeaderPanelComponent

final class ChatToastAlertPanelNode: ChatTitleAccessoryPanelNode {
    private let separatorNode: ASDisplayNode
    private let titleNode: ImmediateTextNode
    
    private let activateAreaNode: AccessibilityAreaNode
    
    private var textColor: UIColor = .black {
        didSet {
            if !self.textColor.isEqual(oldValue) {
                self.titleNode.attributedText = NSAttributedString(string: self.text, font: Font.regular(14.0), textColor: self.textColor)
            }
        }
    }
    
    var text: String = "" {
        didSet {
            if self.text != oldValue {
                self.titleNode.attributedText = NSAttributedString(string: text, font: Font.regular(14.0), textColor: self.textColor)
                self.setNeedsLayout()
                
                if UIAccessibility.isVoiceOverRunning {
                    let announcement = ChatToastAlertPanelVoiceOver.resolve(text: text).label
                    if !announcement.isEmpty {
                        DispatchQueue.main.async {
                            UIAccessibility.post(notification: .announcement, argument: announcement as NSString)
                        }
                    }
                }
            }
        }
    }
    
    override init() {
        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true
        
        self.titleNode = ImmediateTextNode()
        self.titleNode.attributedText = NSAttributedString(string: "", font: Font.regular(14.0), textColor: UIColor.black)
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.insets = UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
        
        self.activateAreaNode = AccessibilityAreaNode()
        self.activateAreaNode.accessibilityTraits = [.staticText]
        
        super.init()

        self.addSubnode(self.titleNode)
        self.addSubnode(self.separatorNode)
        self.addSubnode(self.activateAreaNode)
    }
    
    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState) -> LayoutResult {
        let panelHeight: CGFloat = 40.0

        self.textColor = interfaceState.theme.rootController.navigationBar.primaryTextColor
        self.separatorNode.backgroundColor = interfaceState.theme.chat.historyNavigation.strokeColor
        
        transition.updateFrame(node: self.separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: width, height: UIScreenPixel)))
        
        let titleSize = self.titleNode.updateLayout(CGSize(width: width - leftInset - rightInset - 20.0, height: 100.0))
        self.titleNode.frame = CGRect(origin: CGPoint(x: floor((width - titleSize.width) / 2.0), y: floor((panelHeight - titleSize.height) / 2.0)), size: titleSize)
        
        self.activateAreaNode.frame = CGRect(origin: .zero, size: CGSize(width: width, height: panelHeight))
        let resolved = ChatToastAlertPanelVoiceOver.resolve(text: self.titleNode.attributedText?.string ?? "")
        self.activateAreaNode.accessibilityLabel = resolved.label
        self.activateAreaNode.accessibilityTraits = resolved.traits
        
        return LayoutResult(backgroundHeight: panelHeight, insetHeight: panelHeight, hitTestSlop: 0.0)
    }
}
