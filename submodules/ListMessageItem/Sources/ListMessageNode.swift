import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import AccountContext
import TelegramCore
import TelegramPresentationData
import TelegramStringFormatting
import LocalizedPeerData

public class ListMessageNode: ListViewItemNode {
    var item: ListMessageItem?
    var interaction: ListMessageItemInteraction?
    
    required init() {
        super.init(layerBacked: false)
    }
    
    func setupItem(_ item: ListMessageItem) {
        self.item = item
        self.updateAccessibility()
    }

    private func updateAccessibility() {
        guard let item = self.item, let message = item.message else {
            self.isAccessibilityElement = false
            self.accessibilityLabel = nil
            self.accessibilityValue = nil
            self.accessibilityHint = nil
            self.accessibilityTraits = []
            
            if self.isNodeLoaded {
                self.view.isAccessibilityElement = false
                self.view.accessibilityLabel = nil
                self.view.accessibilityValue = nil
                self.view.accessibilityHint = nil
                self.view.accessibilityTraits = []
            }
            return
        }
        
        let strings = item.presentationData.strings
        
        let chatTitle: String?
        if message.id.peerId == item.context.account.peerId {
            chatTitle = strings.DialogList_SavedMessages
        } else {
            chatTitle = message.peers[message.id.peerId].flatMap(EnginePeer.init)?.displayTitle(strings: strings, displayOrder: item.presentationData.nameDisplayOrder)
        }
        
        var authorName: String?
        if message.flags.contains(.Incoming), let author = message.author, author.id != message.id.peerId {
            authorName = EnginePeer(author).displayTitle(strings: strings, displayOrder: item.presentationData.nameDisplayOrder)
        }
        
        let summaryText = descriptionStringForMessage(
            contentSettings: item.context.currentContentSettings.with { $0 },
            message: EngineMessage(message),
            strings: strings,
            nameDisplayOrder: item.presentationData.nameDisplayOrder,
            dateTimeFormat: item.presentationData.dateTimeFormat,
            accountPeerId: item.context.account.peerId
        ).0.string
        
        let isSelected: Bool
        if case let .selectable(selected) = item.selection {
            isSelected = selected
        } else {
            isSelected = false
        }
        
        let voiceOver = ListMessageItemVoiceOver.resolve(
            strings: strings,
            chatTitle: chatTitle,
            authorName: authorName,
            summary: summaryText,
            isSelected: isSelected
        )
        
        self.isAccessibilityElement = voiceOver.isAccessibilityElement
        self.accessibilityLabel = voiceOver.label
        self.accessibilityValue = voiceOver.value
        self.accessibilityHint = voiceOver.hint
        self.accessibilityTraits = voiceOver.traits
        
        if self.isNodeLoaded {
            self.view.isAccessibilityElement = voiceOver.isAccessibilityElement
            self.view.accessibilityLabel = voiceOver.label
            self.view.accessibilityValue = voiceOver.value
            self.view.accessibilityHint = voiceOver.hint
            self.view.accessibilityTraits = voiceOver.traits
        }
    }
    
    override public func accessibilityActivate() -> Bool {
        guard let item = self.item else {
            return false
        }
        
        var supernode: ASDisplayNode? = self
        while let current = supernode {
            if let listView = current as? ListView {
                item.selected(listView: listView)
                return true
            }
            supernode = current.supernode
        }
        
        guard let message = item.message else {
            return false
        }
        if case let .selectable(selected) = item.selection {
            item.interaction.toggleMessagesSelection([message.id], !selected)
            return true
        }
        let _ = item.interaction.openMessage(message, .default)
        return true
    }
    
    override public func layoutForParams(_ params: ListViewItemLayoutParams, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
    }
    
    public func asyncLayout() -> (_ item: ListMessageItem, _ params: ListViewItemLayoutParams, _ mergedTop: Bool, _ mergedBottom: Bool, _ dateAtBottom: Bool) -> (ListViewItemNodeLayout, (ListViewItemUpdateAnimation) -> Void) {
        return { _, params, _, _, _ in
            return (ListViewItemNodeLayout(contentSize: CGSize(width: params.width, height: 1.0), insets: UIEdgeInsets()), { _ in
                
            })
        }
    }
    
    public func transitionNode(id: MessageId, media: Media, adjustRect: Bool) -> (ASDisplayNode, CGRect, () -> (UIView?, UIView?))? {
        return nil
    }
    
    public func updateHiddenMedia() {
    }
    
    public func updateSelectionState(animated: Bool) {
    }
}
