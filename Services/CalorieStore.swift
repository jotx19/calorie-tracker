//
//  CalorieStore.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import Foundation

let kAppGroupID = "group.hello-world.Calorie-Tracker"

final class CalorieStore {
    static let shared = CalorieStore()
    private let defaults: UserDefaults
    private let logKey = "calorieLog_v2"
    private let limitsKey = "nutritionLimits"

    private init() {
        defaults = UserDefaults(suiteName: kAppGroupID) ?? .standard
    }

    // MARK: - Limits
    struct NutritionLimits: Codable {
        var calories: Int = 2000
        var protein: Int = 150
        var carbs: Int = 250
        var fat: Int = 65
    }

    var limits: NutritionLimits {
        get {
            guard let data = defaults.data(forKey: limitsKey),
                  let limits = try? JSONDecoder().decode(NutritionLimits.self, from: data)
            else { return NutritionLimits() }
            return limits
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: limitsKey)
            }
        }
    }

    // MARK: - Entries
    func todayEntries() -> [FoodLogEntry] {
        allEntries().filter { Calendar.current.isDateInToday($0.date) }
    }

    func allEntries() -> [FoodLogEntry] {
        guard let data = defaults.data(forKey: logKey),
              let entries = try? JSONDecoder().decode([FoodLogEntry].self, from: data)
        else { return [] }
        return entries
    }

    func save(_ entry: FoodLogEntry) {
        var all = allEntries()
        all.append(entry)
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        all = all.filter { $0.date > cutoff }
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: logKey)
        }
    }

    func delete(id: UUID) {
        var all = allEntries()
        all.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: logKey)
        }
    }

    // MARK: - Totals
    struct DayTotals {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
    }

    func todayTotals() -> DayTotals {
        todayEntries().reduce(into: DayTotals()) { totals, entry in
            totals.calories += entry.calories
            totals.protein += entry.protein
            totals.carbs += entry.carbs
            totals.fat += entry.fat
        }
    }
}
