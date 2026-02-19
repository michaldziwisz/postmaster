import Foundation
import PeerInfoRatingComponent
import TelegramPresentationData
import UIKit

public enum PeerInfoRatingVoiceOver {
    public static func resolve(strings: PresentationStrings, level: Int) -> PeerInfoRatingComponent.Accessibility {
        let value: String?
        if level < 0 {
            value = strings.ProfileLevelInfo_NegativeRating
        } else {
            value = strings.ProfileLevelInfo_LevelIndex(Int32(level))
        }

        return PeerInfoRatingComponent.Accessibility(
            label: strings.ProfileLevelInfo_RatingTitle,
            value: value,
            hint: strings.VoiceOver_Chat_OpenHint,
            traits: [.button]
        )
    }
}

