import UIKit

public enum MediaPlayerScrubbingNodeVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolve(label: String, timestamp: Double, duration: Double, isEnabled: Bool, isPlaying: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.adjustable]
        if isPlaying {
            traits.insert(.updatesFrequently)
        }
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        return Resolved(
            label: label,
            value: formatTimestamp(max(0.0, min(timestamp, duration))),
            hint: nil,
            traits: traits
        )
    }
    
    public static func seekStep(duration: Double) -> Double {
        duration <= 60.0 ? 1.0 : 5.0
    }
    
    public static func adjustedTimestamp(timestamp: Double, duration: Double, step: Double, direction: Int) -> Double {
        max(0.0, min(duration, timestamp + step * Double(direction)))
    }
    
    private static func formatTimestamp(_ seconds: Double) -> String {
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
}

