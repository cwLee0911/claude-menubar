import Foundation

struct UsageLimitSnapshot: Codable, Equatable {
    struct UsageWindow: Codable, Equatable {
        let usedPercentage: Double?
        let resetsAt: TimeInterval?

        var clampedPercentage: Double? {
            guard let usedPercentage else { return nil }
            return min(100, max(0, usedPercentage))
        }

        var roundedPercentage: Int? {
            clampedPercentage.map { Int($0.rounded()) }
        }

        var resetDate: Date? {
            resetsAt.map(Date.init(timeIntervalSince1970:))
        }
    }

    let schemaVersion: Int
    let planName: String?
    let currentSession: UsageWindow
    let weekly: UsageWindow
    let displayPercentage: Double?
    let updatedAt: TimeInterval

    var menuBarTitle: String {
        guard let pct = roundedDisplayPercentage else { return "--%" }
        return "\(pct)%"
    }

    private var roundedDisplayPercentage: Int? {
        let value = displayPercentage
            ?? currentSession.usedPercentage
            ?? weekly.usedPercentage
        guard let value else { return nil }
        return Int(min(100, max(0, value)).rounded())
    }

    var updatedDate: Date {
        Date(timeIntervalSince1970: updatedAt)
    }
}

extension UsageLimitSnapshot {
    static let mock = UsageLimitSnapshot(
        schemaVersion: 1,
        planName: "Pro",
        currentSession: UsageWindow(
            usedPercentage: 99,
            resetsAt: Date().addingTimeInterval(108 * 60).timeIntervalSince1970
        ),
        weekly: UsageWindow(
            usedPercentage: 40,
            resetsAt: Calendar.current.nextDate(
                after: Date(),
                matching: DateComponents(hour: 18, minute: 59, weekday: 1),
                matchingPolicy: .nextTime
            )?.timeIntervalSince1970
        ),
        displayPercentage: 99,
        updatedAt: Date().timeIntervalSince1970
    )
}
