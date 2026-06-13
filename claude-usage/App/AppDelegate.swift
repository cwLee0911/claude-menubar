import AppKit
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let usageStore = UsageStore()
    private var statusItemController: StatusItemController?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        do {
            try ClaudeStatusLineInstaller.installIfNeeded()
        } catch {
            NSLog("ClaudeUsageBarMac bridge install failed: \(error.localizedDescription)")
        }
        usageStore.start()
        statusItemController = StatusItemController(store: usageStore)
    }
    func applicationWillTerminate(_ notification: Notification) {
        usageStore.stop()
    }
}
