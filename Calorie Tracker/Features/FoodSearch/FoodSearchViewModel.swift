//
//  FoodSearchViewModel.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//
import Foundation
import Combine

final class FoodSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [FoodItem] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFood: FoodItem?
    @Published var servings: Double = 1.0

    private let service = FoodSearchService.shared
    private let store = CalorieStore.shared
    private var searchTask: Task<Void, Never>?

    var calculatedCalories: Double { (selectedFood?.calories ?? 0) * servings }
    var calculatedProtein: Double  { (selectedFood?.protein ?? 0) * servings }
    var calculatedCarbs: Double    { (selectedFood?.carbs ?? 0) * servings }
    var calculatedFat: Double      { (selectedFood?.fat ?? 0) * servings }

    func onQueryChange() {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { isLoading = true; error = nil }
            do {
                let items = try await service.search(query: query)
                await MainActor.run { self.results = items; self.isLoading = false }
            } catch {
                await MainActor.run { self.error = "Search failed"; self.isLoading = false }
            }
        }
    }

    func select(_ food: FoodItem) {
        selectedFood = food
        servings = 1.0
    }

    func adjustServings(by delta: Double) {
        servings = max(0.5, servings + delta)
    }

    func logFood() -> Bool {
        guard let food = selectedFood else { return false }
        let entry = FoodLogEntry(
            name: food.name,
            calories: calculatedCalories,
            protein: calculatedProtein,
            carbs: calculatedCarbs,
            fat: calculatedFat,
            servingSize: "\(servings == 1 ? "" : "\(servings)x ")\(food.servingDescription)"
        )
        store.save(entry)
        return true
    }

    func clear() {
        query = ""
        results = []
        selectedFood = nil
        servings = 1.0
        error = nil
    }
}
