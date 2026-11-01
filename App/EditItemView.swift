import SwiftUI

/// Fix a name or price (handy when a site hid its price), or change the wait.
struct EditItemView: View {
    @State var item: WishItem
    let onSave: (WishItem) -> Void
    let onCancel: () -> Void

    @State private var priceText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $item.title, axis: .vertical)
                    HStack {
                        Text("Price")
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                if item.status == .waiting {
                    Section("Sleep on it for") {
                        Picker("Wait", selection: $item.waitDays) {
                            ForEach(AppConfig.waitOptions, id: \.self) { Text("\($0) days").tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                Section {
                    LabeledContent("Added", value: item.addedAt.formatted(date: .abbreviated, time: .shortened))
                    Link(destination: item.url) {
                        Text(item.url.absoluteString).lineLimit(2)
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let price = item.price { priceText = String(format: "%.2f", price) }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = item
                        updated.price = MetadataFetcher.parsePrice(priceText)
                        onSave(updated)
                    }
                    .bold()
                }
            }
        }
    }
}
