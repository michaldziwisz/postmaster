import TelegramPresentationData
import TelegramUIPreferences

public enum ThemeCarouselItemVoiceOver {
    public static func resolveLabel(strings: PresentationStrings, themeReference: PresentationThemeReference?) -> String {
        if let themeReference {
            return themeDisplayName(strings: strings, reference: themeReference)
        } else {
            return strings.Wallpaper_NoWallpaper
        }
    }
}

