import Foundation
import TelegramPresentationData
import UIKit

public enum CallListCallItemVoiceOver {
    public struct Resolved: Equatable {
        public var label: String
        public var value: String?
        public var hint: String?
        public var traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(
        strings: PresentationStrings,
        title: String,
        status: String?,
        date: String?,
        isEditing: Bool
    ) -> Resolved {
        var valueParts: [String] = []
        if let status, !status.isEmpty {
            valueParts.append(status)
        }
        if let date, !date.isEmpty {
            valueParts.append(date)
        }
        let value = valueParts.isEmpty ? nil : valueParts.joined(separator: ", ")
        
        let traits: UIAccessibilityTraits = [.button]
        let hint: String? = nil
        
        return Resolved(
            label: title,
            value: value,
            hint: hint,
            traits: traits
        )
    }
}
