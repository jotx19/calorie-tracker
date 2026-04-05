import WidgetKit
import SwiftUI

// MARK: - Widget Timeline Entry
struct CalorieEntry: TimelineEntry {
    let date: Date
    let totalCalories: Double
    let dailyLimit: Int
    let recentItems: [FoodLogEntry]
}

// MARK: - Timeline Provider
struct CalorieProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieEntry {
        CalorieEntry(date: Date(), totalCalories: 1240, dailyLimit: 2000, recentItems: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh every 15 minutes + midnight refresh
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let nextUpdate = min(midnight, Date().addingTimeInterval(900))
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> CalorieEntry {
        let store = SharedCalorieStore.shared
        return CalorieEntry(
            date: Date(),
            totalCalories: store.todayTotalCalories(),
            dailyLimit: store.dailyLimit,
            recentItems: Array(store.loadTodayEntries().suffix(3))
        )
    }
}

// MARK: - Widget Main
struct CalorieWidget: Widget {
    let kind: String = "CalorieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieProvider()) { entry in
            CalorieWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calorie Tracker")
        .description("Track your daily calories at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View
struct CalorieWidgetEntryView: View {
    var entry: CalorieProvider.Entry
    @Environment(\.widgetFamily) var family

    var progress: Double {
        min(entry.totalCalories / Double(entry.dailyLimit), 1.0)
    }

    var remaining: Double {
        max(Double(entry.dailyLimit) - entry.totalCalories, 0)
    }

    var ringColor: Color {
        progress > 1.0 ? .red : progress > 0.85 ? .orange : .green
    }

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry, progress: progress, remaining: remaining, ringColor: ringColor)
        case .systemMedium:
            MediumWidgetView(entry: entry, progress: progress, remaining: remaining, ringColor: ringColor)
        default:
            SmallWidgetView(entry: entry, progress: progress, remaining: remaining, ringColor: ringColor)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: CalorieEntry
    let progress: Double
    let remaining: Double
    let ringColor: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(ringColor)
                    .font(.caption2)
                Text("Calories")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            ZStack {
                Circle()
                    .trim(from: 0.1, to: 0.9)
                    .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(126))
                
                Circle()
                    .trim(from: 0.1, to: 0.1 + 0.8 * progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(126))
                
                VStack(spacing: 0) {
                    Text("\(Int(entry.totalCalories))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(ringColor)
                    Text("kcal")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 75, height: 75)
            
            HStack {
                Text("\(Int(remaining))")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                Text("left")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("/\(entry.dailyLimit)")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .widgetURL(URL(string: "calorietracker://add"))
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: CalorieEntry
    let progress: Double
    let remaining: Double
    let ringColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Left: Ring
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .trim(from: 0.1, to: 0.9)
                        .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(126))

                    Circle()
                        .trim(from: 0.1, to: 0.1 + 0.8 * progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(126))

                    VStack(spacing: 0) {
                        Text("\(Int(entry.totalCalories))")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(ringColor)
                        Text("kcal")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 85, height: 85)

                Text("\(Int(remaining)) remaining")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            // Right: Recent log
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "list.bullet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Today's Log")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 2)

                if entry.recentItems.isEmpty {
                    Spacer()
                    Text("No food logged yet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Tap to add food")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Spacer()
                } else {
                    ForEach(entry.recentItems) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(item.calories))")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundStyle(ringColor)
                        }
                    }
                    Spacer()
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(ringColor)
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(14)
        .widgetURL(URL(string: "calorietracker://add"))
    }
}

// MARK: - Widget Bundle
@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget {
        CalorieWidget()
    }
}
