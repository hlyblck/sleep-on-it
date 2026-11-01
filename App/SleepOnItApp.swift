import SwiftUI

@main
struct SleepOnItApp: App {
    @StateObject private var store = ItemStore.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(.indigo)
                .onAppear { Notifier.requestPermission() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    // Pick up anything saved from the share sheet, and make sure every reminder is scheduled.
                    store.reload()
                    Notifier.rescheduleAll(store.items)
                }
        }
    }
}
