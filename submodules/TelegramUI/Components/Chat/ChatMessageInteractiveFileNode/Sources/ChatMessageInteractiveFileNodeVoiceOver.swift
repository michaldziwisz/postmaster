import TelegramPresentationData
import UIKit
import UniversalMediaPlayer

public enum ChatMessageInteractiveFileNodeVoiceOver {
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        public let traits: UIAccessibilityTraits
        
        public init(label: String, value: String?, hint: String?, traits: UIAccessibilityTraits) {
            self.label = label
            self.value = value
            self.hint = hint
            self.traits = traits
        }
    }
    
    public static func resolvePlaybackButton(strings: PresentationStrings, isPlaying: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button, .startsMediaSession]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(
            label: isPlaying ? strings.VoiceOver_Media_PlaybackPause : strings.VoiceOver_Media_PlaybackPlay,
            value: nil,
            hint: nil,
            traits: traits
        )
    }
    
    public static func resolveDownloadButton(strings: PresentationStrings, isFetching: Bool, isEnabled: Bool) -> Resolved {
        var traits: UIAccessibilityTraits = [.button]
        if !isEnabled {
            traits.insert(.notEnabled)
        }
        return Resolved(
            label: isFetching ? strings.DownloadList_CancelDownloading : strings.WebBrowser_Download_Download,
            value: nil,
            hint: nil,
            traits: traits
        )
    }
    
    public static func shouldActivate(isEnabled: Bool) -> Bool {
        return isEnabled
    }
    
    public static func effectiveTimestamp(status: MediaPlayerStatus) -> Double {
        if status.generationTimestamp > 0.0, case .playing = status.status {
            return status.timestamp + (CACurrentMediaTime() - status.generationTimestamp) * status.baseRate
        } else {
            return status.timestamp
        }
    }
    
    public static func resolveWaveform(label: String, timestamp: Double, duration: Double, isEnabled: Bool, isPlaying: Bool) -> MediaPlayerScrubbingNodeVoiceOver.Resolved {
        MediaPlayerScrubbingNodeVoiceOver.resolve(
            label: label,
            timestamp: timestamp,
            duration: duration,
            isEnabled: isEnabled,
            isPlaying: isPlaying
        )
    }
    
    public static func seekStep(duration: Double) -> Double {
        MediaPlayerScrubbingNodeVoiceOver.seekStep(duration: duration)
    }
    
    public static func adjustedTimestamp(timestamp: Double, duration: Double, step: Double, direction: Int) -> Double {
        MediaPlayerScrubbingNodeVoiceOver.adjustedTimestamp(
            timestamp: timestamp,
            duration: duration,
            step: step,
            direction: direction
        )
    }
}
