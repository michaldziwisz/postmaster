import TelegramPresentationData
import TelegramUIPreferences
import ThemeCarouselItem
import XCTest

final class ThemeCarouselItemVoiceOverTests: XCTestCase {
    func testResolveLabelNoThemeUsesNoWallpaperString() {
        let label = ThemeCarouselItemVoiceOver.resolveLabel(strings: defaultPresentationStrings, themeReference: nil)
        XCTAssertEqual(label, defaultPresentationStrings.Wallpaper_NoWallpaper)
    }
    
    func testResolveLabelBuiltinDayUsesDisplayName() {
        let label = ThemeCarouselItemVoiceOver.resolveLabel(strings: defaultPresentationStrings, themeReference: .builtin(.day))
        XCTAssertEqual(label, defaultPresentationStrings.Appearance_ThemeCarouselDay)
    }
    
    func testResolveLabelBuiltinClassicUsesDisplayName() {
        let label = ThemeCarouselItemVoiceOver.resolveLabel(strings: defaultPresentationStrings, themeReference: .builtin(.dayClassic))
        XCTAssertEqual(label, defaultPresentationStrings.Appearance_ThemeCarouselClassic)
    }
}

