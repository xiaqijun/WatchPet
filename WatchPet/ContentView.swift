import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject private var store: PetStore
    @EnvironmentObject private var syncManager: WatchCompanionSyncManager

    var body: some View {
        VStack(spacing: 8) {
            header

            Spacer(minLength: 2)

            PetSpriteView(action: store.currentAction)
                .frame(width: 128, height: 128)
                .onTapGesture {
                    store.strokePet()
                    WKInterfaceDevice.current().play(.click)
                }

            syncSummary

            statusBars

            HStack(spacing: 8) {
                Button("喂食") {
                    store.feed()
                    WKInterfaceDevice.current().play(.success)
                }
                .font(.caption2)

                Button("睡觉") {
                    store.sleep()
                    WKInterfaceDevice.current().play(.start)
                }
                .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .onAppear {
            store.refreshDerivedAction()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(syncManager.syncedPackage?.name ?? store.pet.name)
                    .font(.headline)
                    .lineLimit(1)
                if let synced = syncManager.syncedPackage {
                    Text("来自 iPhone · \(synced.selectedAction)")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text("Lv.\(store.pet.level)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var syncSummary: some View {
        Group {
            if syncManager.syncedPackage != nil {
                Text(syncManager.lastStatusMessage)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var statusBars: some View {
        VStack(spacing: 3) {
            MeterRow(label: "饱", value: store.pet.hunger, color: .orange)
            MeterRow(label: "心", value: store.pet.mood, color: .pink)
            MeterRow(label: "精", value: store.pet.energy, color: .blue)
        }
    }
}

struct MeterRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9))
                .frame(width: 14)
            ProgressView(value: Double(value), total: 100)
                .tint(color)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PetStore.preview)
        .environmentObject(WatchCompanionSyncManager())
}
