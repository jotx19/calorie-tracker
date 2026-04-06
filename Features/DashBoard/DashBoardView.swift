//
//  DashboardView.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//

import SwiftUI
import WidgetKit
import Charts

// MARK: - Main Dashboard
struct DashboardView: View {
    @StateObject private var vm = DashboardViewModel()
    @State private var showAdd = false
    @State private var showSettings = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Week Strip
                    WeekStripView(selectedDate: $selectedDate)
                        .padding(.top, 8)

                    // Three-color rings
                    CalorieRingsView(vm: vm)
                        .padding(.top, 24)

                    // Macro stat bar
                    MacroStatsBar(vm: vm)
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    // Calorie Trends chart
                    WeeklyChartView(vm: vm)
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    // Today's Log
                    LogListView(vm: vm)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: refresh) {
                AddFoodView()
            }
            .sheet(isPresented: $showSettings, onDismiss: refresh) {
                SettingsView()
            }
            .onAppear(perform: refresh)
        }
    }

    private func refresh() {
        vm.load()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Week Strip
struct WeekStripView: View {
    @Binding var selectedDate: Date
    private let days: [Date] = {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-3...3).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(days, id: \.self) { day in
                    DayCell(date: day, isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate))
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedDate = day
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool

    private var dayLetter: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(3)).uppercased()
    }

    private var dayNum: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayLetter)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? .primary : .secondary)

            ZStack {
                Circle()
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .frame(width: 36, height: 36)

                Text(dayNum)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .white : .primary)
            }

            Circle()
                .fill(isToday ? Color.accentColor : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(width: 44)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Three-Color Rings
struct CalorieRingsView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        ZStack {
            MacroRing(progress: vm.progress(for: .calories), color: .green, size: 180, lineWidth: 14)
            MacroRing(progress: vm.progress(for: .protein), color: .blue, size: 148, lineWidth: 10)
            MacroRing(progress: vm.progress(for: .carbs), color: .orange, size: 120, lineWidth: 10)
            MacroRing(progress: vm.progress(for: .fat), color: .pink, size: 92, lineWidth: 10)

            VStack(spacing: 2) {
                Text("\(Int(vm.totals.calories))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 200)
        .padding(.top, 12)
    }
}

struct MacroRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)
        }
    }
}

// MARK: - Macro Stats Bar
struct MacroStatsBar: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        HStack(spacing: 0) {
            MacroStatCell(
                label: "Calories",
                value: Int(vm.totals.calories),
                limit: vm.limits.calories,
                color: .green
            )

            Divider().frame(height: 40)

            MacroStatCell(
                label: "Protein",
                value: Int(vm.totals.protein),
                limit: vm.limits.protein,
                color: .blue,
                unit: "g"
            )

            Divider().frame(height: 40)

            MacroStatCell(
                label: "Carbs",
                value: Int(vm.totals.carbs),
                limit: vm.limits.carbs,
                color: .orange,
                unit: "g"
            )

            Divider().frame(height: 40)

            MacroStatCell(
                label: "Fat",
                value: Int(vm.totals.fat),
                limit: vm.limits.fat,
                color: .pink,
                unit: "g"
            )
        }
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MacroStatCell: View {
    let label: String
    let value: Int
    let limit: Int
    let color: Color
    var unit: String = "kcal"

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("/ \(limit)\(unit)")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weekly Chart
struct WeeklyChartView: View {
    @ObservedObject var vm: DashboardViewModel

    private var chartData: [(day: String, calories: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let all = CalorieStore.shared.allEntries()
        let f = DateFormatter()
        f.dateFormat = "EEE"

        return (0..<7).reversed().map { offset -> (String, Double) in
            let date = cal.date(byAdding: .day, value: -offset, to: today)!
            let total = all
                .filter { cal.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.calories }
            return (f.string(from: date), total)
        }
    }

    private var underGoalDays: Int {
        chartData.filter { $0.calories > 0 && $0.calories <= Double(vm.limits.calories) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calorie Trends")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Last 7 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(underGoalDays)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                    Text("days under goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart(chartData, id: \.day) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Calories", item.calories)
                )
                .foregroundStyle(
                    item.day == chartData.last?.day
                        ? Color.orange
                        : Color(.tertiarySystemFill)
                )
                .cornerRadius(6)

                RuleMark(y: .value("Goal", Double(vm.limits.calories)))
                    .foregroundStyle(Color.green.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Goal")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.green.opacity(0.7))
                            .padding(.trailing, 4)
                    }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color(.separator).opacity(0.4))
                    AxisValueLabel()
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 10))
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.secondary)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Log List
struct LogListView: View {
    @ObservedObject var vm: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Log")
                .font(.headline)
                .padding(.horizontal, 20)

            if vm.entries.isEmpty {
                Text("Nothing logged yet — tap + to add food")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                List {
                    ForEach(vm.entries) { entry in
                        LogEntryRow(entry: entry)
                            .listRowInsets(EdgeInsets()) // full width
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(vm.entries.count) * 80)
            }
        }
    }

    private func delete(_ entry: FoodLogEntry) {
        vm.delete(id: entry.id)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct LogEntryRow: View {
    let entry: FoodLogEntry

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

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
            .padding(.vertical, 14)
            .padding(.horizontal, 20)

            Divider() // bottom border
        }
        .background(Color.clear)
    }
}
