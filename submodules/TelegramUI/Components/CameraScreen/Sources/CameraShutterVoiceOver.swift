import Foundation
import TelegramPresentationData

public enum CameraShutterVoiceOver {
    public enum State: Equatable {
        case takePhoto
        case startVideoRecording
        case stopVideoRecording
        case startLiveStream
    }
    
    public struct Resolved: Equatable {
        public let label: String
        public let value: String?
        public let hint: String?
        
        public init(label: String, value: String? = nil, hint: String? = nil) {
            self.label = label
            self.value = value
            self.hint = hint
        }
    }
    
    public static func resolve(strings: PresentationStrings, state: State) -> Resolved {
        switch state {
        case .takePhoto:
            return Resolved(label: strings.Common_TakePhoto)
        case .startVideoRecording:
            return Resolved(label: strings.VoiceOver_Camera_StartVideoRecording)
        case .stopVideoRecording:
            return Resolved(label: strings.VoiceOver_Camera_StopVideoRecording)
        case .startLiveStream:
            return Resolved(label: strings.Camera_LiveStream_StartLiveStream)
        }
    }
}

