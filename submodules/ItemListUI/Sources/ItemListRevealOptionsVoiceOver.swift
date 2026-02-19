import UIKit

public enum ItemListRevealOptionsVoiceOver {
    public static func resolveCustomActions(
        options: (left: [ItemListRevealOption], right: [ItemListRevealOption]),
        perform: @escaping (ItemListRevealOption) -> Bool
    ) -> [UIAccessibilityCustomAction] {
        var actions: [UIAccessibilityCustomAction] = []
        actions.reserveCapacity(options.left.count + options.right.count)
        
        for option in options.left {
            guard !option.title.isEmpty else {
                continue
            }
            actions.append(UIAccessibilityCustomAction(name: option.title, actionHandler: {
                perform(option)
            }))
        }
        
        for option in options.right {
            guard !option.title.isEmpty else {
                continue
            }
            actions.append(UIAccessibilityCustomAction(name: option.title, actionHandler: {
                perform(option)
            }))
        }
        
        return actions
    }
}

