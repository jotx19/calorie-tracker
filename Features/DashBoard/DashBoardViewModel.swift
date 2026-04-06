//
//  DashBoardViewModel.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    @Published var entries: [FoodLogEntry] = []
    @Published var totals: CalorieStore.DayTotals = .init()
    @Published var limits: CalorieStore.NutritionLimits = .init()

    private let store = CalorieStore.shared

    func load() {
        entries = store.todayEntries()
        totals = store.todayTotals()
        limits = store.limits
    }

    func delete(id: UUID) {
        store.delete(id: id)
        load()
    }

    // Progress 0...1
    func progress(for macro: Macro) -> Double {
        let value: Double
        let limit: Double
        switch macro {
        case .calories: value = totals.calories; limit = Double(limits.calories)
        case .protein:  value = totals.protein;  limit = Double(limits.protein)
        case .carbs:    value = totals.carbs;    limit = Double(limits.carbs)
        case .fat:      value = totals.fat;      limit = Double(limits.fat)
        }
        guard limit > 0 else { return 0 }
        return min(value / limit, 1.0)
    }

    func remaining(for macro: Macro) -> Double {
        switch macro {
        case .calories: return max(Double(limits.calories) - totals.calories, 0)
        case .protein:  return max(Double(limits.protein) - totals.protein, 0)
        case .carbs:    return max(Double(limits.carbs) - totals.carbs, 0)
        case .fat:      return max(Double(limits.fat) - totals.fat, 0)
        }
    }
}

enum Macro: CaseIterable {
    case calories, protein, carbs, fat

    var label: String {
        switch self {
        case .calories: return "Cal"
        case .protein:  return "Pro"
        case .carbs:    return "Carb"
        case .fat:      return "Fat"
        }
    }

    var unit: String {
        switch self {
        case .calories: return "kcal"
        default:        return "g"
        }
    }
}
