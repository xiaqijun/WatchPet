import SwiftUI

struct ContentView: View {
    @State private var package: PetPackage?
    @State private var selectedAction: PetAction = .idle
    @State private var errorMessage: String?
    @StateObject private var syncManager = CompanionWatchSyncManager()

    var body: some View {
        NavigationStack {
            Group {
                if let package {
                    preview(package)
                } else if let errorMessage {
                    ContentUnavailableView("加载失败", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else {
                    ProgressView("加载示例宠物包…")
                }
            }
            .navigationTitle("WatchPet")
            .task { loadSamplePackage() }
        }
    }

    private func preview(_ package: PetPackage) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(package.name)
                    .font(.largeTitle.bold())
                Text("\(package.species) · \(package.style)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.thinMaterial)
                if let animation = package.animations[selectedAction] {
                    SpriteAnimationView(animation: animation)
                        .padding(36)
                }
            }
            .frame(height: 300)
            .padding(.horizontal)

            Picker("动作", selection: $selectedAction) {
                ForEach(package.sortedActions) { action in
                    Text(action.title).tag(action)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                Section("同步到 Apple Watch") {
                    Button {
                        syncManager.send(package: package, selectedAction: selectedAction)
                    } label: {
                        Label("发送当前宠物", systemImage: "applewatch")
                    }
                    LabeledContent("配对", value: syncManager.isPaired ? "是" : "否")
                    LabeledContent("已安装", value: syncManager.isWatchAppInstalled ? "是" : "否")
                    LabeledContent("可实时到达", value: syncManager.isReachable ? "是" : "否")
                    Text(syncManager.lastStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("资源包") {
                    LabeledContent("ID", value: package.id)
                    LabeledContent("画布", value: "\(package.canvas.width)×\(package.canvas.height)")
                    LabeledContent("动作数", value: "\(package.animations.count)")
                }

                Section("当前动作") {
                    if let animation = package.animations[selectedAction] {
                        LabeledContent("名称", value: selectedAction.title)
                        LabeledContent("FPS", value: "\(animation.fps)")
                        LabeledContent("帧数", value: "\(animation.frameURLs.count)")
                        LabeledContent("循环", value: animation.loop ? "是" : "否")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func loadSamplePackage() {
        do {
            package = try WatchPetPackageLoader.shared.loadBundledSample()
            selectedAction = package?.sortedActions.first ?? .idle
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
