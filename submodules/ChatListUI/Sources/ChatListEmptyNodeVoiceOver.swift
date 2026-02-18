import Foundation

public struct ChatListEmptyNodeVoiceOver {
    public static func resolve(title: String, description: String?) -> String {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let description, !description.isEmpty {
            return "\(title)\n\(description)"
        } else {
            return title
        }
    }
}

