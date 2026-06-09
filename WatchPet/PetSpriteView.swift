import SwiftUI
import ImageIO

struct PetSpriteView: View {
    let action: PetAction
    let importedPackage: ImportedPetPackage?

    @State private var frameIndex = 0
    private let timer = Timer.publish(every: 0.22, on: .main, in: .common).autoconnect()

    init(action: PetAction, importedPackage: ImportedPetPackage? = nil) {
        self.action = action
        self.importedPackage = importedPackage
    }

    var body: some View {
        Group {
            if let frameURL = importedFrameURL {
                fileImage(frameURL)
            } else {
                Image(frameName)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
            }
        }
        .id(action.rawValue)
        .transition(.scale.combined(with: .opacity))
        .onReceive(timer) { _ in
            frameIndex = (frameIndex + 1) % max(activeFrameCount, 1)
        }
        .onChange(of: action) { _, _ in
            frameIndex = 0
        }
        .onChange(of: importedPackage?.id) { _, _ in
            frameIndex = 0
        }
    }

    @ViewBuilder
    private func fileImage(_ url: URL) -> some View {
        if let image = cgImage(from: url) {
            Image(decorative: image, scale: 1.0)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            fallbackImage
        }
    }

    private func cgImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private var fallbackImage: some View {
        Image(frameName)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }

    private var importedFrameURL: URL? {
        let frames = importedPackage?.frameURLs(for: action) ?? []
        guard !frames.isEmpty else { return nil }
        return frames[frameIndex % frames.count]
    }

    private var activeFrameCount: Int {
        let importedCount = importedPackage?.frameURLs(for: action).count ?? 0
        return importedCount > 0 ? importedCount : frameCount(for: action)
    }

    private var frameName: String {
        "\(action.rawValue)_\(frameIndex % frameCount(for: action))"
    }

    private func frameCount(for action: PetAction) -> Int {
        switch action {
        case .idle: return 4
        case .happy: return 6
        case .hungry: return 4
        case .eat: return 6
        case .sleep: return 4
        case .pet: return 6
        case .sad: return 4
        case .levelUp: return 8
        }
    }
}

#Preview {
    PetSpriteView(action: .idle)
        .frame(width: 128, height: 128)
}
