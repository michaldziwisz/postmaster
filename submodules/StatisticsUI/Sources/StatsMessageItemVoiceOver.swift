import ItemListUI
import TelegramPresentationData
import UIKit

public struct StatsMessageItemVoiceOver {
    public struct Resolved: Equatable {
        public let label: String?
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String?, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(
        strings: PresentationStrings,
        title: String?,
        date: String?,
        views: String?,
        reactionsValue: String?,
        publicSharesValue: String?,
        isEnabled: Bool
    ) -> Resolved {
        var valueComponents: [String] = []
        if let date, !date.isEmpty {
            valueComponents.append(date)
        }
        if let views, !views.isEmpty {
            valueComponents.append(views)
        }
        if let reactionsValue, !reactionsValue.isEmpty {
            valueComponents.append("\(strings.Stats_Message_Reactions): \(reactionsValue)")
        }
        if let publicSharesValue, !publicSharesValue.isEmpty {
            valueComponents.append("\(strings.Stats_Message_PublicShares): \(publicSharesValue)")
        }
        
        let value = valueComponents.isEmpty ? nil : valueComponents.joined(separator: ", ")
        let resolved = ItemListRowVoiceOver.resolve(strings: strings, kind: isEnabled ? .open : .staticText, isEnabled: isEnabled)
        
        return Resolved(
            label: title,
            value: value,
            hint: resolved.hint,
            traits: resolved.traits
        )
    }
}

