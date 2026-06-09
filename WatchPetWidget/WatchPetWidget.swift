import WidgetKit
import SwiftUI

struct WatchPetWidgetEntry: TimelineEntry {
    let date: Date
    let name: String
    let level: Int
    let mood: Int
}

struct WatchPetWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchPetWidgetEntry {
        WatchPetWidgetEntry(date: Date(), name: "Mochi", level: 1, mood: 80)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchPetWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchPetWidgetEntry>) -> Void) {
        let entry = placeholder(in: context)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct WatchPetWidgetView: View {
    let entry: WatchPetWidgetEntry

    var body: some View {
        VStack(spacing: 2) {
            Image("idle_0")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
            Text("Lv.\(entry.level)")
                .font(.caption2)
        }
    }
}

@main
struct WatchPetWidget: Widget {
    let kind = "WatchPetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchPetWidgetProvider()) { entry in
            WatchPetWidgetView(entry: entry)
        }
        .configurationDisplayName("WatchPet")
        .description("查看你的手表宠物状态。")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
