import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Shows the "Sleep on it" form when you pick Sleep On It from the iOS share sheet.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        Task { @MainActor in
            let sharedLink = await extractSharedLink() ?? ""
            let form = AddItemForm(
                urlText: sharedLink,
                onSave: { [weak self] item in
                    ItemStore.shared.add(item)
                    self?.extensionContext?.completeRequest(returningItems: nil)
                },
                onCancel: { [weak self] in
                    self?.extensionContext?.cancelRequest(withError: NSError(domain: "SleepOnIt", code: 0))
                }
            )
            .tint(.indigo)

            let host = UIHostingController(rootView: form)
            addChild(host)
            host.view.frame = view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(host.view)
            host.didMove(toParent: self)
        }
    }

    /// Safari shares a URL; many shopping apps share text that contains a URL.
    private func extractSharedLink() async -> String? {
        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        let providers = items.flatMap { $0.attachments ?? [] }

        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL,
               url.scheme?.hasPrefix("http") == true {
                return url.absoluteString
            }
        }
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String,
               let url = URLExtract.firstURL(in: text) {
                return url.absoluteString
            }
        }
        for item in items {
            if let text = item.attributedContentText?.string, let url = URLExtract.firstURL(in: text) {
                return url.absoluteString
            }
        }
        return nil
    }
}
