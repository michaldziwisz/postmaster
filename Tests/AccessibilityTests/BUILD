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
        "//submodules/ChatListUI",
        "//submodules/TelegramUI",
        "//submodules/TelegramUI/Components/ChatTitleView",
        "//submodules/TelegramUI/Components/Chat/ChatMessageAnimatedStickerItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageBubbleItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageInstantVideoItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageStickerItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatTextInputActionButtonsNode",
        "//submodules/ContactsPeerItem",
        "//submodules/ContactListUI",
        "//submodules/HorizontalPeerItem",
        "//submodules/ListMessageItem",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUI/Components/ActionPanelComponent",
        "//submodules/TelegramUI/Components/ChatListHeaderComponent",
        "//submodules/TelegramUI/Components/HorizontalTabsComponent",
        "//submodules/TelegramUI/Components/MoreHeaderButton",
        "//submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen",
        "//submodules/TelegramUI/Components/Stories/StoryPeerListComponent",
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
