import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let watchPetPackage = UTType(filenameExtension: "watchpet") ?? .zip
}

struct ContentView: View {
    @State private var package: PetPackage?
    @State private var selectedAction: PetAction = .idle
    @State private var errorMessage: String?
    @State private var isImporterPresented = false
    @StateObject private var syncManager = CompanionWatchSyncManager()
    @StateObject private var library = PetPackageLibrary()

    var body: some View {
        NavigationStack {
            Group {
                if let package {
                    preview(package)
                } else if let errorMessage {
                    ContentUnavailableView("Load failed", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else {
                    ProgressView("Loading sample pet...")
                }
            }
            .navigationTitle("WatchPet")
            .toolbar {
                Button {
                    isImporterPresented = true
                } label: {
                    Label("Import", systemImage: "folder.badge.plus")
                }
            }
            .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.folder, .zip, .watchPetPackage]) { result in
                handleImport(result)
            }
            .task { loadSamplePackage() }
        }
    }

    private func preview(_ package: PetPackage) -> some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(package.name)
                    .font(.largeTitle.bold())
                Text("\(package.species) - \(package.style)")
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

            Picker("Action", selection: $selectedAction) {
                ForEach(package.sortedActions) { action in
                    Text(action.title).tag(action)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                Section("Send to Apple Watch") {
                    Button {
                        syncManager.send(package: package, selectedAction: selectedAction)
                    } label: {
                        Label("Send current pet and resources", systemImage: "applewatch")
                    }
                    LabeledContent("Paired", value: syncManager.isPaired ? "Yes" : "No")
                    LabeledContent("Watch app", value: syncManager.isWatchAppInstalled ? "Installed" : "Missing")
                    LabeledContent("Reachable", value: syncManager.isReachable ? "Yes" : "No")
                    LabeledContent("Pending files", value: "\(syncManager.pendingFileTransfers)")
                    Text(syncManager.lastStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Package") {
                    LabeledContent("ID", value: package.id)
                    LabeledContent("Canvas", value: "\(package.canvas.width)x\(package.canvas.height)")
                    LabeledContent("Actions", value: "\(package.animations.count)")
                    Text(library.lastMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Selected animation") {
                    if let animation = package.animations[selectedAction] {
                        LabeledContent("Action", value: selectedAction.title)
                        LabeledContent("FPS", value: "\(animation.fps)")
                        LabeledContent("Frames", value: "\(animation.frameURLs.count)")
                        LabeledContent("Loop", value: animation.loop ? "Yes" : "No")
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func loadSamplePackage() {
        do {
            package = try library.loadBundledSample()
            selectedAction = package?.sortedActions.first ?? .idle
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let imported = try library.importPackage(from: url)
            package = imported
            selectedAction = imported.sortedActions.first ?? .idle
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
