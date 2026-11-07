import SwiftUI
import UIKit

/// Small info screen, opened from the ⓘ button. Holds the feedback link.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    static let feedbackEmail = "haleymblock@gmail.com"

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private var feedbackURL: URL? {
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = Self.feedbackEmail
        parts.queryItems = [
            URLQueryItem(name: "subject", value: "Sleep On It feedback"),
            URLQueryItem(name: "body", value: "\n\n\n—\nApp version \(appVersion) · iOS \(UIDevice.current.systemVersion)")
        ]
        return parts.url
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        if let url = feedbackURL { openURL(url) }
                    } label: {
                        Label("Send feedback or request a feature", systemImage: "envelope")
                    }
                } footer: {
                    Text("Opens an email to the person who made this app. Ideas, bugs and \"I wish it did…\" are all welcome.")
                }

                Section("How it works") {
                    Label("Save something you want. Pick a wait or a date.", systemImage: "plus.circle")
                    Label("Get a nudge when the wait is over.", systemImage: "bell")
                    Label("Skip it, and the money counts as saved.", systemImage: "checkmark.seal")
                    Label("Your list stays on your phone. Nothing is sent anywhere.", systemImage: "lock")
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
