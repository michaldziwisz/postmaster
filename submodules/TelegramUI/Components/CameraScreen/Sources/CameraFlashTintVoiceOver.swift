import CoreGraphics
import Foundation
import UIKit
import TelegramPresentationData

public enum CameraFlashTintVoiceOver {
    public enum Swatch: Equatable {
        case off
        case white
        case yellow
        case blue
    }
    
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String? = nil, hint: String? = nil, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolveSwatch(strings: PresentationStrings, swatch: Swatch, isSelected: Bool) -> Resolved {
        let value: String
        switch swatch {
        case .off:
            value = strings.Camera_FlashOff
        case .white:
            value = strings.WallpaperSearch_ColorWhite
        case .yellow:
            value = strings.WallpaperSearch_ColorYellow
        case .blue:
            value = strings.WallpaperSearch_ColorBlue
        }
        
        var traits: UIAccessibilityTraits = [.button]
        if isSelected {
            traits.insert(.selected)
        }
        
        return Resolved(label: strings.VoiceOver_Camera_FlashTint, value: value, hint: nil, traits: traits)
    }
    
    public static func resolveSlider(strings: PresentationStrings, value: CGFloat) -> Resolved {
        let clamped = max(0.0, min(1.0, value))
        let percent = Int((clamped * 100.0).rounded())
        return Resolved(
            label: strings.VoiceOver_Camera_FlashTintSize,
            value: "\(percent)%",
            hint: strings.VoiceOver_Camera_FlashTintSizeHint,
            traits: [.adjustable]
        )
    }
}
