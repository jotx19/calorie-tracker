//
//  FoodItem.swift
//  Calorie Tracker
//
//  Created by Prabjot Singh on 2026-04-06.
//

import Foundation

struct FoodItem: Identifiable {
    let fdcId: Int
    let name: String
    let brand: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var id: Int { fdcId }

    var servingDescription: String {
        if let size = servingSize, let unit = servingSizeUnit {
            return "\(Int(size))\(unit)"
        }
        return "100g"
    }

    var emoji: String {
        let n = name.lowercased()
        if n.contains("apple") { return "🍎" }
        if n.contains("banana") { return "🍌" }
        if n.contains("chicken") { return "🍗" }
        if n.contains("beef") || n.contains("steak") { return "🥩" }
        if n.contains("fish") || n.contains("salmon") || n.contains("tuna") { return "🐟" }
        if n.contains("rice") { return "🍚" }
        if n.contains("egg") { return "🥚" }
        if n.contains("milk") { return "🥛" }
        if n.contains("bread") { return "🍞" }
        if n.contains("pizza") { return "🍕" }
        if n.contains("coffee") { return "☕" }
        if n.contains("orange") { return "🍊" }
        if n.contains("broccoli") { return "🥦" }
        if n.contains("carrot") { return "🥕" }
        if n.contains("potato") { return "🥔" }
        if n.contains("burger") { return "🍔" }
        if n.contains("pasta") || n.contains("spaghetti") { return "🍝" }
        if n.contains("cheese") { return "🧀" }
        if n.contains("chocolate") { return "🍫" }
        if n.contains("avocado") { return "🥑" }
        if n.contains("salad") { return "🥗" }
        return "🍽️"
    }
}

// MARK: - USDA Decodable Models
struct USDASearchResponse: Decodable {
    let foods: [USDAFood]
}

struct USDAFood: Decodable {
    let fdcId: Int
    let description: String
    let brandOwner: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let foodNutrients: [USDANutrient]?

    func toFoodItem() -> FoodItem {
        let cal = nutrientValue(id: 1008)
        let protein = nutrientValue(id: 1003)
        let carbs = nutrientValue(id: 1005)
        let fat = nutrientValue(id: 1004)

        let serving = servingSize ?? 100.0
        let factor = serving / 100.0

        return FoodItem(
            fdcId: fdcId,
            name: description,
            brand: brandOwner,
            servingSize: servingSize,
            servingSizeUnit: servingSizeUnit,
            calories: cal * factor,
            protein: protein * factor,
            carbs: carbs * factor,
            fat: fat * factor
        )
    }

    private func nutrientValue(id: Int) -> Double {
        foodNutrients?.first(where: { $0.nutrientId == id })?.value ?? 0
    }
}

struct USDANutrient: Decodable {
    let nutrientId: Int?
    let value: Double?
}
