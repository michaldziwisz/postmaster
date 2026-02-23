
test_suite(
    name = "AllTests",
    tests = [
        ":AccessibilityStringsLintTests",
        "//Tests/AccessibilityTests:VoiceOverOverlayTests",
    ],
    visibility = [
        "//visibility:public",
    ],
)

test_suite(
    name = "AllTestsExtended",
    tests = [
        ":AccessibilityStringsLintTests",
        "//Tests/AccessibilityTests:VoiceOverOverlayTests",
        "//Tests/AccessibilityTests:AccessibilitySmokeTests",
    ],
    visibility = [
        "//visibility:public",
    ],
)

sh_test(
    name = "AccessibilityStringsLintTests",
    srcs = [
        "AccessibilityStringsLintTests.sh",
    ],
    data = [
        "//submodules/TelegramUI:TelegramUIAccessibilityLintSources",
    ],
)
