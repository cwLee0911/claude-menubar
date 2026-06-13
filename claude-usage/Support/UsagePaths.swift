import Foundation

enum UsagePaths {
    static let appSupportDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/ClaudeUsageLimits", isDirectory: true)

    static let usageFileURL: URL = appSupportDirectory
        .appendingPathComponent("usage.json")

    static let bridgeScriptURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/claude-usage-limit-bridge.sh")

    static let originalStatusLineCommandURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/claude-usage-limit-original-command.txt")

    static let claudeSettingsURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")
}
