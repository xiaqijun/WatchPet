import SwiftUI

@main
struct WatchPetApp: App {
    @StateObject private var store = PetStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    await store.bootstrap()
                }
        }
    }
}
