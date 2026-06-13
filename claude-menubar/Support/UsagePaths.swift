import Foundation

enum UsagePaths {
    static let appSupportDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/ClaudeMenubar", isDirectory: true)

    static let usageFileURL: URL = appSupportDirectory
        .appendingPathComponent("usage.json")

    static let bridgeScriptURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/claude-menubar-bridge.sh")

    static let originalStatusLineCommandURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/claude-menubar-original-command.txt")

    static let claudeSettingsURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/settings.json")
}
