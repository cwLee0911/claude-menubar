import AppKit
import Combine
import Darwin
import Foundation

final class UsageStore: ObservableObject {
    @Published private(set) var snapshot: UsageLimitSnapshot?
    @Published private(set) var displayedWeekly: UsageLimitSnapshot.UsageWindow?
    @Published private(set) var weeklyDisplayUpdatedDate: Date?
    @Published private(set) var now = Date()

    private let decoder = JSONDecoder()
    private var source: DispatchSourceFileSystemObject?
    private var directoryFileDescriptor: CInt = -1
    private var clockTimer: Timer?
    private var lifecycleObservers: [NSObjectProtocol] = []

    var hasUsage: Bool {
        snapshot?.currentSession.effectivePercentage(now: now) != nil
            || displayedWeekly?.effectivePercentage(now: now) != nil
            || snapshot?.weekly.effectivePercentage(now: now) != nil
    }

    var weeklyForDisplay: UsageLimitSnapshot.UsageWindow? {
        displayedWeekly ?? snapshot?.weekly
    }

    func start() {
        do {
            try FileManager.default.createDirectory(
                at: UsagePaths.appSupportDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            NSLog("claude-menubar could not create support directory: \(error.localizedDescription)")
        }

        load()
        startMonitoringDirectory()
        startClock()
        startObservingLifecycle()
    }

    func stop() {
        source?.cancel()
        source = nil
        clockTimer?.invalidate()
        clockTimer = nil
        for observer in lifecycleObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
    }

    func refreshClock() {
        now = Date()
    }

    func refreshWeeklyDisplay() {
        guard let snapshot else { return }
        displayedWeekly = snapshot.weekly
        weeklyDisplayUpdatedDate = snapshot.updatedDate
    }

    func load() {
        now = Date()
        do {
            let data = try Data(contentsOf: readableUsageFileURL())
            let nextSnapshot = try decoder.decode(UsageLimitSnapshot.self, from: data)
            snapshot = nextSnapshot

            if displayedWeekly == nil {
                displayedWeekly = nextSnapshot.weekly
                weeklyDisplayUpdatedDate = nextSnapshot.updatedDate
            }
        } catch {
            NSLog("claude-menubar failed to load usage data: \(error.localizedDescription)")
            snapshot = nil
        }
    }

    private func readableUsageFileURL() -> URL {
        if FileManager.default.fileExists(atPath: UsagePaths.usageFileURL.path) {
            return UsagePaths.usageFileURL
        }
        return UsagePaths.legacyUsageFileURL
    }

    private func startMonitoringDirectory() {
        guard source == nil else { return }

        directoryFileDescriptor = open(UsagePaths.appSupportDirectory.path, O_EVTONLY)
        guard directoryFileDescriptor >= 0 else {
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryFileDescriptor,
            eventMask: [.write, .rename, .delete, .extend, .attrib],
            queue: DispatchQueue.global(qos: .utility)
        )

        source.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.load()
            }
        }

        let fd = directoryFileDescriptor
        source.setCancelHandler {
            if fd >= 0 {
                close(fd)
            }
        }

        source.resume()
        self.source = source
    }

    private func startClock() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshClock()
        }
    }

    /// The clock `Timer` does not fire while the Mac is asleep, so after waking
    /// `now` would still hold yesterday's value and an expired reset window
    /// would keep showing its stale percentage. Re-sync the clock (and reload
    /// the file, in case it changed while we were inactive) whenever the system
    /// wakes or the app returns to the foreground.
    private func startObservingLifecycle() {
        let resync: (Notification) -> Void = { [weak self] _ in
            DispatchQueue.main.async {
                self?.load()
                self?.refreshClock()
            }
        }

        lifecycleObservers.append(
            NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main,
                using: resync
            )
        )
        lifecycleObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main,
                using: resync
            )
        )
    }

}
