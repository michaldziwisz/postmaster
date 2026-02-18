import TelegramPresentationData
import UIKit

public enum TrimViewHandleVoiceOver {
    public enum Handle: Equatable {
        case start
        case end
    }
    
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
    
    public static func resolve(strings: PresentationStrings, handle: Handle, position: Double, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.adjustable]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        
        let label: String
        switch handle {
        case .start:
            label = strings.BusinessMessageSetup_ScheduleStartTime
        case .end:
            label = strings.BusinessMessageSetup_ScheduleEndTime
        }
        
        return Resolved(
            label: label,
            value: formatTimestamp(position),
            hint: nil,
            traits: traits
        )
    }
    
    public static func adjustRange(
        handle: Handle,
        startPosition: Double,
        endPosition: Double,
        duration: Double,
        minDuration: Double,
        maxDuration: Double,
        step: Double,
        direction: Int
    ) -> (startPosition: Double, endPosition: Double) {
        guard duration > 0.0 else {
            return (0.0, 0.0)
        }
        
        let boundedMinDuration = max(0.0, min(minDuration, duration))
        let boundedMaxDuration = max(boundedMinDuration, min(maxDuration, duration))
        let delta = step * Double(direction)
        
        switch handle {
        case .start: {
            var updatedStartPosition = startPosition + delta
            updatedStartPosition = max(0.0, min(updatedStartPosition, endPosition - boundedMinDuration))
            
            var updatedEndPosition = endPosition
            if updatedEndPosition - updatedStartPosition > boundedMaxDuration {
                let excess = (updatedEndPosition - updatedStartPosition) - boundedMaxDuration
                updatedEndPosition = max(updatedStartPosition + boundedMinDuration, updatedEndPosition - excess)
            }
            
            updatedStartPosition = max(0.0, min(updatedStartPosition, duration))
            updatedEndPosition = max(0.0, min(updatedEndPosition, duration))
            
            return (updatedStartPosition, updatedEndPosition)
        }()
        case .end: {
            var updatedEndPosition = endPosition + delta
            updatedEndPosition = min(duration, max(updatedEndPosition, startPosition + boundedMinDuration))
            
            var updatedStartPosition = startPosition
            if updatedEndPosition - updatedStartPosition > boundedMaxDuration {
                let excess = (updatedEndPosition - updatedStartPosition) - boundedMaxDuration
                updatedStartPosition = updatedStartPosition + excess
            }
            
            updatedStartPosition = max(0.0, min(updatedStartPosition, updatedEndPosition - boundedMinDuration))
            updatedEndPosition = max(0.0, min(updatedEndPosition, duration))
            
            return (updatedStartPosition, updatedEndPosition)
        }()
        }
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

