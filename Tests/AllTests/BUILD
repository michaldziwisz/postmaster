
test_suite(
    name = "AllTests",
    tests = [
        ":AccessibilityStringsLintTests",
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
