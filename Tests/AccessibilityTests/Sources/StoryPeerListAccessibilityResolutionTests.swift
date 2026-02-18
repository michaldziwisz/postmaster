import StoryPeerListComponent
import TelegramPresentationData
import XCTest

final class StoryPeerListAccessibilityResolutionTests: XCTestCase {
    func testSelfNoItemsResolvesAddStory() {
        XCTAssertTrue(Thread.isMainThread)
        
        let strings = defaultPresentationStrings
        let resolved = StoryPeerListItemVoiceOver.resolve(
            strings: strings,
            peerTitle: "Me",
            isSelf: true,
            hasItems: false,
            unseenCount: 0,
            uploadProgress: nil
        )
        
        XCTAssertEqual(resolved.label, strings.StoryFeed_AddStory)
        XCTAssertEqual(resolved.hint, strings.VoiceOver_Stories_AddHint)
        XCTAssertNil(resolved.value)
    }
    
    func testOtherPeerUnseenResolvesNewStoriesValue() {
        XCTAssertTrue(Thread.isMainThread)
        
        let strings = defaultPresentationStrings
        let resolved = StoryPeerListItemVoiceOver.resolve(
            strings: strings,
            peerTitle: "Alice",
            isSelf: false,
            hasItems: true,
            unseenCount: 3,
            uploadProgress: nil
        )
        
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.hint, strings.VoiceOver_Stories_OpenHint)
        XCTAssertEqual(resolved.value, strings.VoiceOver_Stories_NewStories(3))
    }
    
    func testUploadingProgressOverridesUnseenCount() {
        XCTAssertTrue(Thread.isMainThread)
        
        let strings = defaultPresentationStrings
        let resolved = StoryPeerListItemVoiceOver.resolve(
            strings: strings,
            peerTitle: "Alice",
            isSelf: false,
            hasItems: true,
            unseenCount: 5,
            uploadProgress: 0.4
        )
        
        XCTAssertEqual(resolved.label, "Alice")
        XCTAssertEqual(resolved.hint, strings.VoiceOver_Stories_OpenHint)
        XCTAssertEqual(resolved.value, strings.VoiceOver_Stories_UploadingProgress("40%").string)
    }
}
