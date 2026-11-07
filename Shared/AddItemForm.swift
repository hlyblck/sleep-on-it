import SwiftUI

/// The "add an item" screen. Used both inside the app (+ button) and in the share sheet.
struct AddItemForm: View {
    @State var urlText: String
    let onSave: (WishItem) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var autoTitle = ""
    @State private var priceText = ""
    @State private var imageURL: URL?
    @State private var waitDays = AppConfig.defaultWait   // 0 means "Pick date"
    @State private var customDate = Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date()
    @State private var isLoading = false
    @State private var fetchedFor: URL?

    private var parsedURL: URL? { URLExtract.firstURL(in: urlText) }

    private var plannedReadyDate: Date {
        waitDays == 0
            ? WaitMath.morning(of: customDate)
            : Calendar.current.date(byAdding: .day, value: waitDays, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Link") {
                    TextField("Paste a product link", text: $urlText, axis: .vertical)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .lineLimit(1...3)
                    if urlText.isEmpty {
                        PasteButton(payloadType: String.self) { strings in
                            Task { @MainActor in urlText = strings.first ?? "" }
                        }
                    }
                }

                Section("Item") {
                    HStack(alignment: .top, spacing: 12) {
                        ItemThumbnail(url: imageURL, size: 64)
                        if isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Fetching details…").foregroundStyle(.secondary)
                            }
                            .frame(maxHeight: .infinity)
                        } else {
                            TextField("Name", text: $title, axis: .vertical)
                                .lineLimit(1...3)
                        }
                    }
                    HStack {
                        Text("Price")
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    Picker("Wait", selection: $waitDays) {
                        ForEach(AppConfig.waitOptions, id: \.self) { days in
                            Text("\(days) days").tag(days)
                        }
                        Text("Pick date").tag(0)
                    }
                    .pickerStyle(.segmented)
                    if waitDays == 0 {
                        DatePicker("Ready on", selection: $customDate, in: WaitMath.tomorrow..., displayedComponents: .date)
                    }
                } header: {
                    Text("Sleep on it for")
                } footer: {
                    Text("You'll get a nudge on \(plannedReadyDate.formatted(.dateTime.weekday(.wide).month(.wide).day())).")
                }
            }
            .navigationTitle("Sleep on it")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .bold()
                        .disabled(parsedURL == nil)
                }
            }
            .task(id: urlText) {
                // Small pause so we don't fetch on every keystroke.
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                await fetchDetails()
            }
        }
    }

    private func fetchDetails() async {
        guard let url = parsedURL, url != fetchedFor else { return }
        fetchedFor = url
        isLoading = true
        let info = await MetadataFetcher.fetch(url)
        isLoading = false
        if let fetchedTitle = info.title, title.isEmpty || title == autoTitle {
            title = fetchedTitle
            autoTitle = fetchedTitle
        }
        if let image = info.imageURL { imageURL = image }
        if priceText.isEmpty, let price = info.price {
            priceText = String(format: "%.2f", price)
        }
    }

    private func save() {
        guard let url = parsedURL else { return }
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = WishItem(
            url: url,
            title: name.isEmpty ? (url.host ?? url.absoluteString) : name,
            imageURL: imageURL,
            price: MetadataFetcher.parsePrice(priceText),
            waitDays: waitDays == 0 ? WaitMath.daysUntil(plannedReadyDate) : waitDays,
            customReadyDate: waitDays == 0 ? plannedReadyDate : nil
        )
        onSave(item)
    }
}

enum WaitMath {
    static var tomorrow: Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
    }

    /// A picked date becomes 9am that day, so the nudge arrives at a sensible hour.
    static func morning(of date: Date) -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }

    static func daysUntil(_ date: Date) -> Int {
        max(1, Int(ceil(date.timeIntervalSinceNow / 86_400)))
    }
}

struct ItemThumbnail: View {
    let url: URL?
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            Image(systemName: "bag")
                .font(.system(size: size * 0.35))
                .foregroundStyle(.secondary)
            if let url {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
