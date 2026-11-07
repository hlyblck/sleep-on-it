import SwiftUI

struct ItemRow: View {
    let item: WishItem
    let onOpen: () -> Void
    let onBought: () -> Void
    let onSkip: () -> Void
    let onUndo: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ItemThumbnail(url: item.imageURL, size: 64)
                .opacity(item.status == .waiting ? 1 : 0.6)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    if let price = item.price {
                        Text(price.asCurrency).fontWeight(.semibold)
                    }
                    if let host = item.url.host {
                        Text(host.replacingOccurrences(of: "www.", with: ""))
                            .lineLimit(1)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text("Added \(item.addedAt.formatted(.dateTime.month(.abbreviated).day())) · \(item.addedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                status
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }

    @ViewBuilder
    private var status: some View {
        switch item.status {
        case .waiting where item.isReady:
            VStack(alignment: .leading, spacing: 8) {
                Label("Wait's over. Still want it?", systemImage: "bell.badge.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                HStack(spacing: 8) {
                    Button("Bought it", action: onBought)
                        .buttonStyle(.bordered)
                    Button("Skip it", action: onSkip)
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
                .controlSize(.small)
            }

        case .waiting:
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: item.progress)
                    .tint(.indigo)
                Text("\(item.daysLeft == 1 ? "1 day" : "\(item.daysLeft) days") left · ready \(item.readyDate.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .bought:
            HStack(spacing: 8) {
                Label("Bought \(decidedText)", systemImage: "bag.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                undoButton
            }

        case .skipped:
            HStack(spacing: 8) {
                Label(item.price.map { "Skipped · saved \($0.asCurrency)" } ?? "Skipped", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                undoButton
            }
        }
    }

    /// Moves the item back to "sleeping on it". Its original countdown is kept.
    private var undoButton: some View {
        Button(action: onUndo) {
            Label("Undo", systemImage: "arrow.uturn.backward")
                .font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.mini)
    }

    private var decidedText: String {
        guard let date = item.decidedAt else { return "" }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}
