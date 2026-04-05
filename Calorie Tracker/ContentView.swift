import SwiftUI
import WidgetKit

// MARK: - Content View (Main App)
struct ContentView: View {
    @StateObject private var searchService = FoodSearchService()
    @State private var entries: [FoodLogEntry] = []
    @State private var showAddFood = false
    @State private var dailyLimit: Int = SharedCalorieStore.shared.dailyLimit

    private var totalCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    private var progress: Double {
        min(totalCalories / Double(dailyLimit), 1.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("Background").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Calorie Ring Header
                    CalorieRingView(
                        total: totalCalories,
                        limit: Double(dailyLimit),
                        progress: progress
                    )
                    .padding(.vertical, 24)

                    // Today's Log
                    List {
                        Section {
                            if entries.isEmpty {
                                Text("No food logged yet today")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(entries) { entry in
                                    FoodLogRow(entry: entry)
                                }
                                .onDelete(perform: deleteEntries)
                            }
                        } header: {
                            Text("Today's Log")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Calorie Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddFood = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView(dailyLimit: $dailyLimit)) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showAddFood, onDismiss: refresh) {
                AddFoodView()
            }
            .onAppear(perform: refresh)
        }
    }

    private func refresh() {
        entries = SharedCalorieStore.shared.loadTodayEntries()
        dailyLimit = SharedCalorieStore.shared.dailyLimit
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteEntries(at offsets: IndexSet) {
        offsets.forEach { i in
            SharedCalorieStore.shared.delete(id: entries[i].id)
        }
        refresh()
    }
}

// MARK: - Calorie Ring
struct CalorieRingView: View {
    let total: Double
    let limit: Double
    let progress: Double

    private var remaining: Double { max(limit - total, 0) }
    private var ringColor: Color {
        progress > 1.0 ? .red : progress > 0.85 ? .orange : .green
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 16)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(total))")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(ringColor)
                    Text("of \(Int(limit)) kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                StatPill(label: "Eaten", value: "\(Int(total))", color: ringColor)
                StatPill(label: "Remaining", value: "\(Int(remaining))", color: .secondary)
            }
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
    }
}

// MARK: - Food Log Row
struct FoodLogRow: View {
    let entry: FoodLogEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.subheadline).fontWeight(.medium)
                Text(entry.servingSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(entry.calories)) kcal")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 2)
    }
}
