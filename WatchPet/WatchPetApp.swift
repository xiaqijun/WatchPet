import SwiftUI

@main
struct WatchPetApp: App {
    @StateObject private var store = PetStore()
    @StateObject private var syncManager = WatchCompanionSyncManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(syncManager)
                .task {
                    await store.bootstrap()
                }
        }
    }
}
