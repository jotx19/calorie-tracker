import SwiftUI
import WidgetKit

// MARK: - Widget Entry
struct CalorieWidgetEntry: TimelineEntry {
    let date: Date
    let totals: CalorieStore.DayTotals
    let limits: CalorieStore.NutritionLimits
}

// MARK: - Provider
struct CalorieWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CalorieWidgetEntry {
        CalorieWidgetEntry(date: Date(), totals: .init(), limits: .init())
    }

    func getSnapshot(in context: Context, completion: @escaping (CalorieWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CalorieWidgetEntry>) -> Void) {
        let next = min(
            Calendar.current.startOfDay(for: Date().addingTimeInterval(86400)),
            Date().addingTimeInterval(900)
        )
        completion(Timeline(entries: [makeEntry()], policy: .after(next)))
    }

    private func makeEntry() -> CalorieWidgetEntry {
        CalorieWidgetEntry(
            date: Date(),
            totals: CalorieStore.shared.todayTotals(),
            limits: CalorieStore.shared.limits
        )
    }
}

// MARK: - Widget Entry View
struct CalorieWidgetEntryView: View {
    let entry: CalorieWidgetEntry
    @Environment(\.widgetFamily) var family

    var calProgress: Double { min(entry.totals.calories / Double(entry.limits.calories), 1.0) }
    var proProgress: Double { min(entry.totals.protein / Double(entry.limits.protein), 1.0) }
    var carbProgress: Double { min(entry.totals.carbs / Double(entry.limits.carbs), 1.0) }
    var fatProgress: Double { min(entry.totals.fat / Double(entry.limits.fat), 1.0) }

    var ringColor: Color { calProgress > 1 ? .red : calProgress > 0.85 ? .orange : .green }

    var body: some View {
        switch family {
        case .systemSmall: SmallWidget(entry: entry, calProgress: calProgress, ringColor: ringColor)
        case .systemMedium: MediumWidget(entry: entry, calProgress: calProgress, proProgress: proProgress, carbProgress: carbProgress, fatProgress: fatProgress, ringColor: ringColor)
        default: SmallWidget(entry: entry, calProgress: calProgress, ringColor: ringColor)
        }
    }
}

// MARK: - Small Widget
struct SmallWidget: View {
    let entry: CalorieWidgetEntry
    let calProgress: Double
    let ringColor: Color

    var remaining: Double { max(Double(entry.limits.calories) - entry.totals.calories, 0) }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(ringColor).font(.caption2)
                Text("Calories").font(.caption2).fontWeight(.medium).foregroundStyle(.secondary)
                Spacer()
            }

            ZStack {
                Circle().trim(from: 0.1, to: 0.9)
                    .stroke(Color.secondary.opacity(0.15), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(126))
                Circle().trim(from: 0.1, to: 0.1 + 0.8 * calProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(126))
                VStack(spacing: 0) {
                    Text("\(Int(entry.totals.calories))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ringColor)
                    Text("kcal").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 72, height: 72)

            HStack {
                Text("\(Int(remaining))").font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                Text("left").font(.system(size: 9)).foregroundStyle(.secondary)
                Spacer()
                Text("/\(entry.limits.calories)").font(.system(size: 9, design: .rounded)).foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .widgetURL(URL(string: "calorietracker://add"))
    }
}

// MARK: - Medium Widget
struct MediumWidget: View {
    let entry: CalorieWidgetEntry
    let calProgress: Double
    let proProgress: Double
    let carbProgress: Double
    let fatProgress: Double
    let ringColor: Color

    var body: some View {
        HStack(spacing: 14) {
            // Nested rings
            ZStack {
                WidgetRing(progress: calProgress, color: ringColor, size: 90, lw: 8)
                WidgetRing(progress: proProgress, color: .blue, size: 72, lw: 6)
                WidgetRing(progress: carbProgress, color: .orange, size: 54, lw: 6)
                WidgetRing(progress: fatProgress, color: .pink, size: 36, lw: 6)
                Text("\(Int(entry.totals.calories))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(ringColor)
            }
            .frame(width: 100, height: 100)

            // Macro list
            VStack(alignment: .leading, spacing: 6) {
                WidgetMacroRow(label: "Cal", value: Int(entry.totals.calories), limit: entry.limits.calories, unit: "kcal", color: ringColor)
                WidgetMacroRow(label: "Pro", value: Int(entry.totals.protein), limit: entry.limits.protein, unit: "g", color: .blue)
                WidgetMacroRow(label: "Carb", value: Int(entry.totals.carbs), limit: entry.limits.carbs, unit: "g", color: .orange)
                WidgetMacroRow(label: "Fat", value: Int(entry.totals.fat), limit: entry.limits.fat, unit: "g", color: .pink)
            }
            Spacer()
        }
        .padding(12)
        .widgetURL(URL(string: "calorietracker://add"))
    }
}

struct WidgetRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lw: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: lw).frame(width: size, height: size)
            Circle().trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lw, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
        }
    }
}

struct WidgetMacroRow: View {
    let label: String
    let value: Int
    let limit: Int
    let unit: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 10)).foregroundStyle(.secondary).frame(width: 26, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.15)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: geo.size.width * min(Double(value) / Double(max(limit, 1)), 1.0), height: 4)
                }
            }
            .frame(height: 4)
            Text("\(value)/\(limit)").font(.system(size: 9, design: .rounded)).foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget
struct CalorieWidget: Widget {
    let kind = "CalorieWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalorieWidgetProvider()) { entry in
            CalorieWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calorie Tracker")
        .description("Track calories and macros at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle
@main
struct CalorieWidgetBundle: WidgetBundle {
    var body: some Widget { CalorieWidget() }
}
