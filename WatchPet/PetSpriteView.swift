import SwiftUI

struct PetSpriteView: View {
    let action: PetAction

    @State private var frameIndex = 0
    private let timer = Timer.publish(every: 0.22, on: .main, in: .common).autoconnect()

    var body: some View {
        Image(frameName)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .id(action.rawValue)
            .transition(.scale.combined(with: .opacity))
            .onReceive(timer) { _ in
                frameIndex = (frameIndex + 1) % frameCount(for: action)
            }
            .onChange(of: action) { _, _ in
                frameIndex = 0
            }
    }

    private var frameName: String {
        "\(action.rawValue)_\(frameIndex)"
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
