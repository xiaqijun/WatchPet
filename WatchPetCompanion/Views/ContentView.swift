import SwiftUI

struct ContentView: View {
    @State private var package: PetPackage?
    @State private var selectedAction: PetAction = .idle
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let package {
                    preview(package)
                } else if let errorMessage {
                    ContentUnavailableView("????", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                } else {
                    ProgressView("????????")
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
                Text("\(package.species) ? \(package.style)")
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

            Picker("??", selection: $selectedAction) {
                ForEach(package.sortedActions) { action in
                    Text(action.title).tag(action)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            List {
                Section("???") {
                    LabeledContent("ID", value: package.id)
                    LabeledContent("??", value: "\(package.canvas.width)?\(package.canvas.height)")
                    LabeledContent("???", value: "\(package.animations.count)")
                }

                Section("????") {
                    if let animation = package.animations[selectedAction] {
                        LabeledContent("??", value: selectedAction.title)
                        LabeledContent("FPS", value: "\(animation.fps)")
                        LabeledContent("??", value: "\(animation.frameURLs.count)")
                        LabeledContent("??", value: animation.loop ? "?" : "?")
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
