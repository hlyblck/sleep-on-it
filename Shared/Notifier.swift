import Foundation
import UserNotifications

/// Local notifications, scheduled on the phone itself — no server needed.
enum Notifier {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func schedule(_ item: WishItem) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        guard item.status == .waiting, item.readyDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Still want it?"
        content.body = "Your \(item.waitDays)-day wait on \(item.title) is over. Buy it or skip it."
        content.sound = .default

        let fireDate = politeTime(for: item.readyDate)
        let interval = max(1, fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger))
    }

    static func cancel(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }

    static func rescheduleAll(_ items: [WishItem]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        items.forEach(schedule)
    }

    /// If the wait ends overnight (say you saved it at 11pm), nudge at 9am instead.
    private static func politeTime(for date: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        if hour >= 9 && hour < 21 { return date }
        let day = hour < 9 ? date : calendar.date(byAdding: .day, value: 1, to: date) ?? date
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? date
    }
}
