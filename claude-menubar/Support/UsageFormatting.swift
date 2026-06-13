import Foundation

enum UsageFormatting {
    private static let weeklyResetFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "'Resets' EEE h:mm a"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "h:mm a"
        return f
    }()

    static func countdownText(for date: Date?, now: Date) -> String {
        guard let date else { return "Checking reset time" }

        let remaining = Int(date.timeIntervalSince(now).rounded())
        if remaining <= 0 { return "Reset" }

        let days = remaining / 86400
        let hours = (remaining % 86400) / 3600
        let minutes = max(0, (remaining % 3600) / 60)

        if days > 0 {
            return "Resets in \(days)d \(hours)h"
        } else if hours > 0 {
            return "Resets in \(hours)h \(minutes)m"
        }
        return "Resets in \(max(1, minutes))m"
    }

    static func sessionResetText(for date: Date?, now: Date) -> String {
        countdownText(for: date, now: now)
    }

    static func weeklyResetText(for date: Date?, now: Date) -> String {
        guard let date else { return "Checking reset" }
        if date <= now { return "Reset" }
        return weeklyResetFormatter.string(from: date)
    }

    static func compactUpdatedText(for date: Date?) -> String {
        guard let date else { return "No updates" }
        return "Updated \(timeFormatter.string(from: date))"
    }
}
