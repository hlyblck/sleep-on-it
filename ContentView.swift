import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ItemStore
    @Environment(\.openURL) private var openURL
    @State private var showingAdd = false
    @State private var editing: WishItem?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SavingsHeader(total: store.totalSaved, count: store.skippedCount)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                if store.items.isEmpty {
                    ContentUnavailableView(
                        "Nothing to sleep on yet",
                        systemImage: "moon.zzz",
                        description: Text("Tap + to paste a link, or share a product page to Sleep On It from Safari or any shopping app.")
                    )
                    .listRowBackground(Color.clear)
                }

                if !store.ready.isEmpty {
                    Section("Wait's over — your call") {
                        ForEach(store.ready) { row($0) }
                    }
                }

                if !store.waiting.isEmpty {
                    Section("Sleeping on it") {
                        ForEach(store.waiting) { row($0) }
                    }
                }

                if !store.decided.isEmpty {
                    Section("Decided") {
                        ForEach(store.decided) { row($0) }
                    }
                }
            }
            .navigationTitle("Sleep On It")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add item")
                }
            }
            .refreshable { store.reload() }
            .sheet(isPresented: $showingAdd) {
                AddItemForm(
                    urlText: "",
                    onSave: { item in
                        store.add(item)
                        showingAdd = false
                    },
                    onCancel: { showingAdd = false }
                )
            }
            .sheet(item: $editing) { item in
                EditItemView(item: item) { updated in
                    store.update(updated)
                    editing = nil
                } onCancel: {
                    editing = nil
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ item: WishItem) -> some View {
        ItemRow(
            item: item,
            onOpen: { openURL(item.url) },
            onBought: { withAnimation { store.decide(item, .bought) } },
            onSkip: { withAnimation { store.decide(item, .skipped) } },
            onUndo: { withAnimation { store.decide(item, .waiting) } }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { withAnimation { store.delete(item) } } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { editing = item } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.orange)
            if item.status == .waiting {
                Button { withAnimation { store.decide(item, .skipped) } } label: {
                    Label("Skip", systemImage: "hand.thumbsdown")
                }
                .tint(.green)
            }
        }
        .swipeActions(edge: .leading) {
            if item.status == .waiting {
                Button { withAnimation { store.decide(item, .bought) } } label: {
                    Label("Bought", systemImage: "bag.fill")
                }
                .tint(.indigo)
            } else {
                Button { withAnimation { store.decide(item, .waiting) } } label: {
                    Label(item.status == .bought ? "Not bought" : "Undo skip", systemImage: "arrow.uturn.backward")
                }
                .tint(.gray)
            }
        }
        .contextMenu {
            Button { openURL(item.url) } label: { Label("Open link", systemImage: "safari") }
            Button { editing = item } label: { Label("Edit", systemImage: "pencil") }
            if item.status == .waiting {
                Button { store.decide(item, .bought) } label: { Label("Bought it", systemImage: "bag") }
                Button { store.decide(item, .skipped) } label: { Label("Skip it", systemImage: "hand.thumbsdown") }
            } else {
                Button { store.decide(item, .waiting) } label: { Label("Move back to waiting", systemImage: "arrow.uturn.backward") }
            }
            Button(role: .destructive) { store.delete(item) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

struct SavingsHeader: View {
    let total: Double
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Saved by sleeping on it")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(total.asCurrency)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(count == 1 ? "1 thing skipped" : "\(count) things skipped")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .padding(.vertical, 8)
    }
}
