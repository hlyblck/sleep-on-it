import Foundation

enum ItemStatus: String, Codable {
    case waiting, bought, skipped
}

struct WishItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var url: URL
    var title: String
    var imageURL: URL?
    var price: Double?
    var addedAt = Date()
    var waitDays: Int = AppConfig.defaultWait
    /// Set when you picked a specific date instead of 7 / 14 / 30 days.
    var customReadyDate: Date?
    var status: ItemStatus = .waiting
    var decidedAt: Date?

    /// When the wait ends. Always measured from when the item was first added,
    /// so editing an item or undoing a decision never restarts the clock.
    var readyDate: Date {
        if let customReadyDate { return customReadyDate }
        return Calendar.current.date(byAdding: .day, value: waitDays, to: addedAt) ?? addedAt
    }

    var isReady: Bool { Date() >= readyDate }

    var daysLeft: Int {
        max(0, Int(ceil(readyDate.timeIntervalSinceNow / 86_400)))
    }

    /// 0…1 — how far through the waiting period we are.
    var progress: Double {
        let total = readyDate.timeIntervalSince(addedAt)
        guard total > 0 else { return 1 }
        return min(1, max(0, Date().timeIntervalSince(addedAt) / total))
    }
}
