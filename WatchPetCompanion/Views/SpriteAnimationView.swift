import SwiftUI
import UIKit

struct SpriteAnimationView: View {
    let animation: PetAnimation

    @State private var frameIndex = 0

    private var interval: TimeInterval {
        1.0 / Double(max(animation.fps, 1))
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { timeline in
            let index = frameIndex(for: timeline.date)
            if let uiImage = UIImage(contentsOfFile: animation.frameURLs[index].path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .accessibilityLabel(Text(animation.action.title))
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.secondary.opacity(0.15))
            .overlay(Text("???").foregroundStyle(.secondary))
    }

    private func frameIndex(for date: Date) -> Int {
        guard !animation.frameURLs.isEmpty else { return 0 }
        let tick = Int(date.timeIntervalSinceReferenceDate / interval)
        if animation.loop {
            return tick % animation.frameURLs.count
        }
        return min(tick % max(animation.frameURLs.count * 2, 1), animation.frameURLs.count - 1)
    }
}
