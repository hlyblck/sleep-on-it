import SwiftUI

/// Edit an item's name, price, link or photo.
/// The countdown is deliberately NOT editable: it always runs from when you first added
/// the item. To start the clock over, add it again as a new item.
struct EditItemView: View {
    @State var item: WishItem
    let onSave: (WishItem) -> Void
    let onCancel: () -> Void

    @State private var priceText = ""
    @State private var linkText = ""
    @State private var isFetching = false

    private var parsedURL: URL? { URLExtract.firstURL(in: linkText) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    HStack(alignment: .top, spacing: 12) {
                        ItemThumbnail(url: item.imageURL, size: 64)
                        TextField("Name", text: $item.title, axis: .vertical)
                            .lineLimit(1...3)
                    }
                    HStack {
                        Text("Price")
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    TextField("Product link", text: $linkText, axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(1...3)
                    Button {
                        Task { await refreshPhoto() }
                    } label: {
                        HStack {
                            Label("Update photo from link", systemImage: "photo")
                            if isFetching {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(parsedURL == nil || isFetching)
                    if item.imageURL != nil {
                        Button("Remove photo", role: .destructive) { item.imageURL = nil }
                    }
                } header: {
                    Text("Link & photo")
                } footer: {
                    if parsedURL == nil {
                        Text("That doesn't look like a web link.")
                    }
                }

                Section {
                    LabeledContent("Added", value: item.addedAt.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("Ready on", value: item.readyDate.formatted(date: .abbreviated, time: .omitted))
                } header: {
                    Text("Countdown")
                } footer: {
                    Text("The countdown runs from when you first added this, so editing doesn't change it. Want to start over? Add it again as a new item.")
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let price = item.price { priceText = String(format: "%.2f", price) }
                linkText = item.url.absoluteString
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = item
                        let name = item.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty { updated.title = name }
                        updated.price = MetadataFetcher.parsePrice(priceText)
                        if let url = parsedURL { updated.url = url }
                        onSave(updated)
                    }
                    .bold()
                    .disabled(parsedURL == nil)
                }
            }
        }
    }

    private func refreshPhoto() async {
        guard let url = parsedURL else { return }
        isFetching = true
        let info = await MetadataFetcher.fetch(url)
        isFetching = false
        if let image = info.imageURL { item.imageURL = image }
    }
}
