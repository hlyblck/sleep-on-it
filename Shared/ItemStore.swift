import Foundation

/// Stores everything in one small JSON file in the shared App Group folder,
/// so the Share Extension and the app see the same list.
@MainActor
final class ItemStore: ObservableObject {
    static let shared = ItemStore()

    @Published private(set) var items: [WishItem] = []
    private let fileURL: URL

    init() {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConfig.appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = base.appendingPathComponent("items.json")
        reload()
    }

    // MARK: Reading

    func reload() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([WishItem].self, from: data)
        else { return }
        if decoded != items { items = decoded }
    }

    var ready: [WishItem] {
        items.filter { $0.status == .waiting && $0.isReady }.sorted { $0.readyDate < $1.readyDate }
    }

    var waiting: [WishItem] {
        items.filter { $0.status == .waiting && !$0.isReady }.sorted { $0.readyDate < $1.readyDate }
    }

    var decided: [WishItem] {
        items.filter { $0.status != .waiting }
            .sorted { ($0.decidedAt ?? .distantPast) > ($1.decidedAt ?? .distantPast) }
    }

    var totalSaved: Double {
        items.filter { $0.status == .skipped }.compactMap(\.price).reduce(0, +)
    }

    var skippedCount: Int {
        items.filter { $0.status == .skipped }.count
    }

    // MARK: Writing (always reload first so the app and extension never overwrite each other)

    func add(_ item: WishItem) {
        reload()
        items.append(item)
        save()
        Notifier.schedule(item)
    }

    func update(_ item: WishItem) {
        reload()
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        save()
        Notifier.schedule(item)
    }

    func decide(_ item: WishItem, _ status: ItemStatus) {
        var changed = item
        changed.status = status
        changed.decidedAt = status == .waiting ? nil : Date()
        update(changed)
    }

    func delete(_ item: WishItem) {
        reload()
        items.removeAll { $0.id == item.id }
        save()
        Notifier.cancel(item.id)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
