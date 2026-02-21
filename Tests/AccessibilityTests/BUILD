load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application", "ios_ui_test", "ios_unit_test")

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

load("//build-system/bazel-utils:plist_fragment.bzl", "plist_fragment")

module_name = "AccessibilityTestHost"

swift_library(
    name = "AccessibilityTestHostLib",
    testonly = True,
    srcs = glob([
        "Host/Sources/**/*.swift",
    ]),
)

plist_fragment(
    name = "AccessibilityTestHostBuildNumberInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleVersion</key>
    <string>1</string>
    """,
)

plist_fragment(
    name = "AccessibilityTestHostVersionInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    """,
)

plist_fragment(
    name = "AccessibilityTestHostAppInfoPlist",
    extension = "plist",
    template =
    """
    <key>CFBundleAllowMixedLocalizations</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Test</string>
    <key>CFBundleIdentifier</key>
    <string>org.telegram.{module_name}</string>
    <key>CFBundleName</key>
    <string>Test</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>ITSAppUsesNonExemptEncryption</key>
    <false/>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
    <key>UIStatusBarStyle</key>
    <string>UIStatusBarStyleDefault</string>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UISupportedInterfaceOrientations~ipad</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
    <key>CADisableMinimumFrameDurationOnPhone</key>
    <true/>
    """.format(module_name=module_name),
)

ios_application(
    name = module_name,
    testonly = True,
    bundle_id = "org.telegram.{}".format(module_name),
    families = ["iphone", "ipad"],
    minimum_os_version = "13.0",
    provisioning_profile = None,
    infoplists = [
        ":AccessibilityTestHostAppInfoPlist",
        ":AccessibilityTestHostBuildNumberInfoPlist",
        ":AccessibilityTestHostVersionInfoPlist",
    ],
    resources = [
        "//Tests/Common:LaunchScreen",
    ],
    deps = [
        "//Tests/Common:Main",
        ":AccessibilityTestHostLib",
    ],
)

swift_library(
    name = "TabBarAccessibilityTestsLib",
    testonly = True,
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    deps = [
        "//submodules/ComponentFlow",
        "//submodules/CallListUI",
        "//submodules/ChatPresentationInterfaceState",
        "//submodules/ChatListUI",
        "//submodules/TelegramUI",
        "//submodules/TelegramUpdateUI",
        "//submodules/TelegramUI/Components/AlertComponent/AlertCheckComponent",
        "//submodules/TelegramUI/Components/AudioTranscriptionButtonComponent",
        "//submodules/TelegramUI/Components/CameraScreen",
        "//submodules/TelegramUI/Components/Calls/VideoChatMicButtonComponent",
        "//submodules/TelegramUI/Components/ChatTitleView",
        "//submodules/TelegramUI/Components/ChatListTitleView",
        "//submodules/TelegramUI/Components/Chat/ChatMessageAnimatedStickerItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageActionButtonsNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageBubbleItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageFactCheckBubbleContentNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageInteractiveFileNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageInstantVideoItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageItemView",
        "//submodules/TelegramUI/Components/Chat/ChatMessageJoinedChannelBubbleContentNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageUnlockMediaNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessagePollBubbleContentNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageSelectionInputPanelNode",
        "//submodules/TelegramUI/Components/Chat/ChatMessageShareButton",
        "//submodules/TelegramUI/Components/Chat/ChatMessageStickerItemNode",
        "//submodules/TelegramUI/Components/Chat/ChatButtonKeyboardInputNode",
        "//submodules/TelegramUI/Components/Chat/ChatBotInfoItem",
        "//submodules/TelegramUI/Components/Chat/ChatQrCodeScreen",
        "//submodules/TelegramUI/Components/Chat/ChatSearchNavigationContentNode",
        "//submodules/TelegramUI/Components/Chat/ChatChannelSubscriberInputPanelNode",
        "//submodules/TelegramUI/Components/Chat/ChatRecordingPreviewInputPanelNode",
        "//submodules/TelegramUI/Components/Chat/ChatTextInputActionButtonsNode",
        "//submodules/TelegramUI/Components/Chat/ChatTextInputPanelNode",
        "//submodules/TelegramUI/Components/Chat/AccessoryPanelNode",
        "//submodules/TelegramUI/Components/ChatScheduleTimeController",
        "//submodules/TelegramUI/Components/EntityKeyboard",
        "//submodules/TelegramUI/Components/MediaScrubberComponent",
        "//submodules/ContactsPeerItem",
        "//submodules/ContactListUI",
        "//submodules/ComposePollUI",
        "//submodules/ShareController",
        "//submodules/Components/ReactionButtonListComponent",
        "//submodules/HorizontalPeerItem",
        "//submodules/CountrySelectionUI",
        "//submodules/AuthorizationUI",
        "//submodules/BotPaymentsUI",
        "//submodules/InviteLinksUI",
        "//submodules/InstantPageUI",
        "//submodules/ListMessageItem",
        "//submodules/MediaPickerUI",
        "//submodules/MediaPlayer:UniversalMediaPlayer",
        "//submodules/QrCodeUI",
        "//submodules/GalleryUI",
        "//submodules/TelegramUI/Components/MediaPlaybackHeaderPanelComponent",
        "//submodules/PremiumUI",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUIPreferences",
        "//submodules/TelegramBaseController",
        "//submodules/TelegramUI/Components/ActionPanelComponent",
        "//submodules/TelegramUI/Components/CameraButtonComponent",
        "//submodules/TelegramUI/Components/ChatList/ChatListFilterTabContainerNode",
        "//submodules/TelegramUI/Components/ChatListHeaderComponent",
        "//submodules/TelegramUI/Components/GlassBarButtonComponent",
        "//submodules/TelegramUI/Components/HorizontalTabsComponent",
        "//submodules/TelegramUI/Components/MoreHeaderButton",
        "//submodules/TelegramUI/Components/NavigationSearchComponent",
        "//submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen",
        "//submodules/TelegramUI/Components/PeerInfo/PeerInfoRatingComponent",
        "//submodules/TelegramUI/Components/Settings/ThemeCarouselItem",
        "//submodules/TelegramUI/Components/Stories/StoryContainerScreen",
        "//submodules/TelegramUI/Components/Stories/StoryFooterPanelComponent",
        "//submodules/TelegramUI/Components/Stories/PeerListItemComponent",
        "//submodules/TelegramUI/Components/Stories/StoryPeerListComponent",
        "//submodules/TelegramUI/Components/Stories/StorySetIndicatorComponent",
        "//submodules/TelegramUI/Components/TabBarComponent",
        "//submodules/TelegramUI/Components/TabSelectorComponent",
        "//submodules/ItemListPeerActionItem",
        "//submodules/ItemListUI",
        "//submodules/LocationUI",
        "//submodules/PeerInfoAvatarListNode",
        "//submodules/PeerInfoUI",
        "//submodules/StatisticsUI",
    ],
)

swift_library(
    name = "AccessibilitySmokeTestsLib",
    testonly = True,
    srcs = [
        "Sources/TabBarComponentAccessibilityTests.swift",
    ],
    deps = [
        "//submodules/ComponentFlow",
        "//submodules/TelegramPresentationData",
        "//submodules/TelegramUI/Components/TabBarComponent",
    ],
)

ios_ui_test(
    name = "AccessibilitySmokeTests",
    bundle_id = "org.telegram.Postmaster.AccessibilitySmokeTests",
    minimum_os_version = "13.0",
    runner = "@build_bazel_rules_apple//apple/testing/default_runner:ios_xctestrun_ordered_runner",
    timeout = "long",
    test_host = ":{}".format(module_name),
    deps = [
        ":AccessibilitySmokeTestsLib",
    ],
    visibility = ["//visibility:public"],
)

ios_unit_test(
    name = "TabBarAccessibilityTests",
    minimum_os_version = "13.0",
    timeout = "long",
    test_host = ":{}".format(module_name),
    deps = [
        ":TabBarAccessibilityTestsLib",
    ],
    visibility = ["//visibility:public"],
)
