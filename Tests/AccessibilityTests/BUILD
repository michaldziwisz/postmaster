load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TabBarAccessibilityTestsLib",
    testonly = True,
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/ComponentFlow",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUI/Components/ChatListHeaderComponent",
        "//submodules/TelegramUI/Components/TabBarComponent",
    ],
)

ios_unit_test(
    name = "TabBarAccessibilityTests",
    minimum_os_version = "13.0",
    runner = "@build_bazel_rules_apple//apple/testing/default_runner:ios_xctestrun_ordered_runner",
    deps = [
        ":TabBarAccessibilityTestsLib",
    ],
    visibility = ["//visibility:public"],
)
